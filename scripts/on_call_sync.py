#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from __future__ import print_function

#import amazoncerts
import json
import os
import subprocess
import httplib2
import oauth2client
import datetime
import pickle
import time
from os.path import expanduser
from dateutil.parser import parse
from dateutil.relativedelta import relativedelta
from retrying import retry
from oauth2client import client
from oauth2client import tools
from oauth2client import file
from apiclient import discovery

from tqdm import tqdm

import sys

try:
    import argparse

    p = argparse.ArgumentParser(parents=[tools.argparser])
    p.add_argument('calendarId',
                   help='Calendar Id where to insert the events\n'
                        + 'You can get it from the iCal URL on google '
                        + 'calendar\nand it looks like this:\n'
                        + 'qkvodipqv8d2mp09uc80a05b0c@group.calendar.google.com')
    p.add_argument('team',
                   help='Name of the team you belong to in the oncall tool\n'
                        + 'You can find this name in the oncall tool website:\n'
                        + 'https://oncall.corp.amazon.com/#/')
    p.add_argument('user',
                   help='Name of the user to retrieve the oncall for. This is\n'
                        + 'usually your user alias, but you can get the oncall for\n'
                        + 'any user in the specified team'
                        + 'You can find the list of users in the oncall tool website:\n'
                        + 'https://oncall.corp.amazon.com/#/')
    flags = p.parse_args()
except ImportError:
    flags = None

SCOPES = 'https://www.googleapis.com/auth/calendar'
HOME_DIR = expanduser("~")
CREDENTIAL_DIR = f'{HOME_DIR}/.credentials'
CLIENT_SECRET_FILE = f'{CREDENTIAL_DIR}/credentials.json'
CREDENTIALS_JSON = 'oncall-gcal-sync.json'
APPLICATION_NAME = 'Oncall Sync for Google Calendar'
MAX_RETRIES_FOR_CALENDAR_INSERTION = 5
MAX_RESULTS = 500

def build_curl_command(team, user):
    year = datetime.datetime.now().year
    start_date = f'{year}-01-01'
    end_date = f'{year}-12-31'
    command = [
        "curl",
        "--anyauth",
        "--location-trusted",
        "-u:",
        f"-b /Users/{user}/.midway/cookie",
        f"-c /Users/{user}/.midway/cookie",
        "-H", "cache-control: no-cache",
        "-H", "accept: application/json",
        f"https://oncall-api.corp.amazon.com/teams/{team}/schedules/detailed?from={start_date}&to={end_date}&desireTimeZone=America/Chicago"
    ]

    return command

def curl_command(team, user):
    date = datetime.date.today()
    start_date = date - relativedelta(months=+3)
    end_date = date + relativedelta(months=+6)
    user = os.environ.get('USER')
    cookie = f'/Users/{user}/.midway/cookie'
    return f'curl --anyauth --location-trusted -u: -b {cookie} -c {cookie} -H "cache-control: no-cache" -H "accept: application/json" "https://oncall-api.corp.amazon.com/teams/{team}/schedules/detailed?from={start_date}&to={end_date}&desireTimeZone=America/Chicago"'


def build_oncall_url(team, user):
    start_date = '2005-01-01'
    end_date = '{year}-12-31'.format(year=datetime.datetime.now().year + 1)
    return "https://oncall-api.corp.amazon.com/teams/{team}/schedules/detailed?from=" \
           "{start_date}&to={end_date}&desireTimeZone=America/Chicago" \
        .format(team=team, user=user, start_date=start_date, end_date=end_date)


def get_credentials():
    """Gets valid user credentials from storage.

    If nothing has been stored, or if the stored credentials are invalid,
    the OAuth2 flow is completed to obtain the new credentials.

    Returns:
        Credentials, the obtained credential.
    """
    credentials = None
    if not os.path.exists(CREDENTIAL_DIR):
        os.makedirs(CREDENTIAL_DIR)
    credential_path = os.path.join(CREDENTIAL_DIR, CREDENTIALS_JSON)
    if os.path.exists(credential_path):
        store = oauth2client.file.Storage(credential_path)
        credentials = store.get()

    if not credentials or credentials.invalid:
      if credentials and credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())
      flow = client.flow_from_clientsecrets(CLIENT_SECRET_FILE, SCOPES)
      flow.user_agent = APPLICATION_NAME
      store = oauth2client.file.Storage(credential_path)
      credentials = store.get()
      if flags:
        credentials = tools.run_flow(flow, store, flags)
      else:  # Needed only for compatability with Python 2.6
        credentials = tools.run(flow, store)
      print('Storing credentials to', credential_path)
    store = oauth2client.file.Storage(credential_path)
    credentials = store.get()
    return credentials


def get_google_calendar_events(service):
    token = None
    now = datetime.datetime(2005, 7, 27, 0, 0, 0).isoformat() + 'Z'
    results = []
    events = service.events().list(
        calendarId=flags.calendarId,
        timeMin=now,
        singleEvents=True,
        maxResults=MAX_RESULTS,
        orderBy='startTime').execute()
    results.extend(events.get('items'))
    
    token = events.get('nextPageToken')
    while token != None:
        events = service.events().list(
            calendarId=flags.calendarId,
            timeMin=now,
            singleEvents=True,
            maxResults=MAX_RESULTS,
            pageToken=token,
            orderBy='startTime').execute()
        token = events.get('nextPageToken')
        results.extend(events.get('items'))
    return results


#@retry(wait_exponential_multiplier=1000, wait_exponential_max=10000, stop_max_attempt_number = MAX_RETRIES_FOR_CALENDAR_INSERTION)
def remove_calendar_events(service, events):
    for event in events:
        for i in range(0, MAX_RETRIES_FOR_CALENDAR_INSERTION):
            try:
                service.events().delete(calendarId=flags.calendarId, eventId=event['id']).execute()
                break
            except Exception:
                if (i >= (MAX_RETRIES_FOR_CALENDAR_INSERTION - 1)):
                    print('Unable to delete from calendar after retries.')
                    raise
                time.sleep(i)

#@retry(wait_exponential_multiplier=1000, wait_exponential_max=10000, stop_max_attempt_number = MAX_RETRIES_FOR_CALENDAR_INSERTION)
def add_calendar_events(service, events):
    for event in events:

        if not event or not event['oncallShift']['oncallMember']:
            continue

        start = event['oncallShift']['startDateTime']
        end = event['oncallShift']['endDateTime']
        start, start_time = event['oncallShift']['startDateTime'].split("T")
        end, end_time = event['oncallShift']['endDateTime'].split("T")
        on_call_status = "daytime"
        start_time = parse(start_time).strftime("%r")
        end_time = parse(end_time).strftime("%r")
        summary = f"{event['oncallShift']['oncallMember'][0]} @ OnCall from {start_time} to {end_time}"

        google_calendar_event = {
            'summary': summary,
            'start': {'date': start},
            'end': {'date': end}
        }

        for i in range(0, MAX_RETRIES_FOR_CALENDAR_INSERTION):
            try:
                service.events().insert(calendarId=flags.calendarId, body=google_calendar_event).execute()
                break
            except Exception:
                if (i >= (MAX_RETRIES_FOR_CALENDAR_INSERTION - 1)):
                    print('Unable to insert into calendar after retries.')
                    raise
                time.sleep(i)

def main():
    # Initialize the Google calendar client
    credentials = get_credentials()
    http = credentials.authorize(httplib2.Http())
    service = discovery.build('calendar', 'v3', http=http)

    # Retrieve OnCall tool events
    print('Obtaining oncall tool events...\n', end='')
    sys.stdout.flush()
    with open(os.devnull, 'w') as devnull:
#        curl_output = subprocess.check_output(build_curl_command(flags.team, flags.user), stderr=devnull)
        print(curl_command(flags.team, flags.user))
        curl_output = os.popen(curl_command(flags.team, flags.user)).read()
    try:
#        oncall_events = json.loads(curl_output.decode('utf-8'))
        oncall_events = json.loads(curl_output)
    except ValueError:
        print('\tFAIL')
        print("Could not read oncall events from the oncall tool. Make sure you've run mwinit -s or you have a valid "
              "kerberos ticket on your laptop")
        exit(1)
    print('\tOK')

    print(len(oncall_events), 'oncall events')
    if len(oncall_events) <= 0:
        print("Unable to fetch oncall events, please try again")
        exit(1)

    # Retrieve Google calendar events
    print('Obtaining google calendar events...', end='')
    sys.stdout.flush()
    google_calendar_events = get_google_calendar_events(service)
    print('\tOK')

    print(len(google_calendar_events), 'events in google calendar')

    # Delete current gcal events
    events = tqdm(google_calendar_events, desc='Deleting previous events from google calendar...')
    remove_calendar_events(service, events)

    # Upload the OnCall tool events
    events = tqdm(oncall_events, desc='Uploading new events...')
    add_calendar_events(service, events)

    print('Done!')


if __name__ == "__main__":
    main()
