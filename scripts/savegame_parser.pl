#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  savegame_parser.pl
#
#        USAGE:  ./savegame_parser.pl  
#
#  DESCRIPTION: i #!/usr/bin/perl
#-----------------------------------
# Wii Savegame Parser
#       written by Lockhool
#             for #wiidev @ EFnet
#-----------------------------------

use strict;
use Fcntl;

sub readLong($;$);
sub readByte($;$);
sub readString($);
sub readUpto($$);
sub readBlock($$;$);
sub readEof();

my $file_in=shift;
die("\n Usage: ./wiiparse.pl <datafile>\n\n")
    unless(sysopen(IN,$file_in,O_RDONLY));

my $add=0;
my $in;

readUpto('Header',0x00000070);
readLong('Magic',0x426B0001);
readLong('WiiID');
my $numfiles = readLong('NumFiles');
readLong('FileDataLen');
readLong('Magic',0x00000000);
readLong('Magic',0x00000000);
readLong('PostHeadLen');
readBlock('Zeros',64);
readLong('Magic',0x00010000);
readLong('PrgID');
readLong('MacAdd');
readLong('Magic',0xF5550000);
readBlock('Hash1',16,'hash1');
for(1..$numfiles){   
   readLong('Magic'.$_,0x03ADF17E);
   my $filesize = readLong('Filesize'.$_);
   readByte('Magic'.$_,0x34);
   readByte('Magic'.$_,0x00);
   readByte('Magic'.$_,0x01);
   my $strlen = readString('Filename'.$_);
   readBlock('StrFiller'.$_,117-$strlen,'f'.$_.'sfill');
   readBlock('Filedata'.$_,$filesize,'f'.$_.'data');
   readBlock('DataFiller'.$_,$filesize % 64,'f'.$_.'dfill');
}
readBlock('Hash2',60,'hash2');
readLong('Magic',0x00000000);
readLong('Magic',0x00010002);
readBlock('Hash3',60,'hash3');
readBlock('Zeros',64);
my $strlen = readString('RootCA');
readBlock('Zeros',64-$strlen);
readLong('Magic',0x00000002);
my $strlen = readString('NG');
readBlock('Zeros',64-$strlen);
readBlock('Hash4',64,'hash4');
readBlock('Zeros',60);
readLong('Magic',0x00010002);
readBlock('Hash5',60,'hash5');
readBlock('Zeros',64);
my $strlen = readString('RootCA-MS-NG');
readBlock('Zeros',64-$strlen);
readLong('Magic',0x00000002);
my $strlen = readString('AP');
readBlock('Zeros',64-$strlen);
readLong('Magic',0x00000000);
readBlock('Hash6',60,'hash6');
readEof;

close(IN);

sub readLong($;$){
   printf("% 12u : ",$add);
   my $name=shift;
   my $val=shift;
   die("!! '$name' premature EOF !!\n")
   unless(4==sysread(IN,$in,4));
   $in=unpack("N",$in);
   $add+=4;
   printf("  LONG '$name' 0x%08X (%u)\n",$in,$in);
   if(defined $val){print(' 'x17);
       if($val==$in){print('==');}else{print('!=')}
	printf(" 0x%08X (%u)\n",$val,$val);
   }
   return($in);
}

sub readByte($;$){
   printf("% 12u : ",$add);
   my $name=shift;
   my $val=shift;
   die("!! '$name' premature EOF !!\n")
   unless(1==sysread(IN,$in,1));
   $in=ord($in);
   $add+=1;
   printf("  BYTE '$name' 0x%02X (%u)\n",$in,$in);
   if(defined $val){print(' 'x17);
       if($val==$in){print('==');}else{print('!=')}
	printf(" 0x%02X (%u)\n",$val,$val);
   }    
   return($in);
}

sub readBlock($$;$){
   printf("% 12u : ",$add);
   my $name=shift;
   my $cnt=shift;
   my $file=shift;
   if(defined $file){$file=$file_in.'.'.$file}
   my $size=$cnt;
   if(defined $file){
	die("!! Can't open $file !!\n")
	unless(sysopen(OUT,$file,O_WRONLY|O_CREAT));}
   while($cnt!=0){
	die("!! '$name' premature EOF !!\n")
	unless(1==sysread(IN,$in,1));
	if(defined $file){syswrite(OUT,$in,1);}
	$add++;
	$cnt--;}
   if(defined $file){close(OUT);}
   printf(" BLOCK '$name' ends after %u bytes\n",$size);
   return($size);
}

sub readString($){
   printf("% 12u : ",$add);
   my $name=shift;   
   my $upto=shift;
   my $size=0;
   my $string='';
   my $in;
   while(1){
	die("!! '$name' premature EOF !!\n")
	unless(1==sysread(IN,$in,1));
	$add+=1;
	$size+=1;
	$string=$string.unpack('a',$in);
	if(ord($in)==0){last;}
   }
   printf("STRING '$name' ends after %u bytes\n",$size);
   print(' 'x15 ."\"$string\"\n");
   return($size);
}

sub readEof(){
   printf("% 12u",$add);
   my $name=shift;   
   my $upto=shift;
   my $size=0;
   my $in;
   while(1){
	last unless(0!=sysread(IN,$in,1));
	$add++;
	$size++;}
   printf(" - %u : EOF reached after %u bytes\n",$add,$size);
   return($size);
}

sub readUpto($$){
   printf("% 12u : ",$add);
   my $name=shift;   
   my $upto=shift;
   my $size=0;
   my $in;
   while(1){
	die("!! '$name' premature EOF !!\n")
	unless(4==sysread(IN,$in,4));
	$add+=4;
	$size+=4;
	if($upto==unpack("N",$in)){last;}}
   printf("  UPTO '$name' ends after %u bytes\n",$size);
   return($size);
}
