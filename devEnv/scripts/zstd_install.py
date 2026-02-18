#!/usr/bin/env python3

import glob, os, platform, shutil, subprocess, tempfile

JAVA_EXTENSIONS_DIR = os.path.expanduser('~/Library/Java/Extensions')
ZSTD_JAR_PATH = 'build/lib/Zstd-JNI.jar'

def bash(command):
    print('Executing Bash command:\n\t' + command)
    result = subprocess.run(command, shell = True, check = True, capture_output = True)
    return result.stdout.decode('UTF-8')

def file_copy(from_path, to_path):
    shutil.copy(from_path, to_path)
    print('Copied {} to {}'.format(os.path.basename(from_path), to_path))

def modify_build_xml():
    with open('build.xml') as file:
        lines = file.readlines()
    mutate = lambda line: line.replace(', scala-test, standard-javadoc', '') if '<target' in line else line
    with open('build.xml', 'w') as file:
        file.writelines(map(mutate, lines))

def extract_dylib(jar_path, target_dir):
    cur_dir = os.path.abspath('.')
    with tempfile.TemporaryDirectory() as temp_dir:
        shutil.copy(jar_path, temp_dir)
        os.chdir(temp_dir)
        bash('unzip ' + os.path.basename(jar_path))
        dylib_file = glob.glob('**/*.dylib', recursive = True)[0]
        file_copy(dylib_file, target_dir)
    os.chdir(cur_dir)

def main():
    if platform.system() == 'Darwin':
        if not os.path.exists(JAVA_EXTENSIONS_DIR):
            os.makedirs(JAVA_EXTENSIONS_DIR)
            print('Created dir:', JAVA_EXTENSIONS_DIR)
        bash('brazil ws use -p Zstd-JNI --mv 1.x')
        cur_dir = os.path.abspath('.')
        zstd_dir = os.path.join(str(os.path.dirname(cur_dir)), 'Zstd-JNI')
        os.chdir(zstd_dir)
        modify_build_xml()
        bash('cd {} && brazil-build release'.format(zstd_dir))
        extract_dylib(ZSTD_JAR_PATH, JAVA_EXTENSIONS_DIR)
        file_copy(ZSTD_JAR_PATH, JAVA_EXTENSIONS_DIR)
        bash('git stash')
        bash('brazil ws remove -p Zstd-JNI')
    else:
        print('Not MacOS - nothing to be done')

if __name__ == '__main__':
    main()
