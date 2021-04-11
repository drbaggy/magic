use feature qw(say);
use strict;
use Data::Dumper qw(Dumper);

my @results = (
  [
    { 'name'     => 'Scherzando Glinda', 'kc_link'  => 'b85b72c7-ff82-eb11-a812-000d3a874408', 'pdo_link' => '#1',
      'sex'     => 'Dam', 'flag'    => '', 'colour'  => 'white and black', 'country' => 'United Kingdom',
      'type'    => 'working', 'kc_code' => '', 'dob'     => '2021-01-09', },
  ],
  [
    { 'name'    => 'Robinsmoor Kite', 'kc_link'    => '2a51a1c3-057c-e911-a8ae-00224800449b', 'pdo_link' => '#2',
      'sex'     => 'Sire', 'flag'    => '', 'colour'  => 'white and black', 'country' => 'United Kingdom',
      'type'    => 'working', 'kc_code' => 'KCSB 4407DB', 'dob'     => '2012-08-04', },
    { 'name'    => 'Scherzando Carcasssonne', 'kc_link'    => 'ba56fff9-057c-e911-a8ab-002248005489', 'pdo_link' => '#3',
      'sex'     => 'Dam', 'flag'    => '', 'colour'  => 'white and black', 'country' => 'United Kingdom',
      'type'    => 'working', 'kc_code' => '', 'dob'     => '2014-05-12',
    },
  ],
  [
    { 'name'    => 'Buckmotts Tonka', 'kc_link' => '55f9e0d1-007c-e911-a8b0-002248004c4b', 'pdo_link' => 'Buckmotts-Tonka/pedigree/38659/i',
      'sex'     => 'Sire', 'flag'    => '', 'colour'  => 'white and black', 'country' => 'United Kingdom',
      'type'    => 'working', 'kc_code' => '', 'dob'     => '2002-07-12', },
    { 'name'    => 'Skersmoor Scamp', 'kc_link' => '60a22b42-067c-e911-a886-00224800492f', 'pdo_link'=> 'Skersmoor-Scamp/pedigree/38655/i',
      'sex'     => 'Dam', 'flag'    => '', 'colour'  => 'white and liver', 'country' => 'United Kingdom',
      'type'    => 'working', 'kc_code' => '', 'dob'     => '2008-05-12', },
    { 'name'    => 'Rothievale Medlar of Edgegrove', 'kc_link' => '96e601d6-057c-e911-a8ab-002248005489', 'pdo_link'=> 'Rothievale-Medlar-Of-Edgegrove/pedigree/15442/i',
      'sex'     => 'Sire', 'flag'    => 'FT CH', 'colour'  => 'white and liver', 'country' => 'United Kingdom', 'type'    => 'working',
      'kc_code' => 'KCSB 4654CX', 'dob'     => '2011-05-17', },
    { 'name'    => 'Scherzando Hathsepsut', 'kc_link' => '108c6cff-057c-e911-a8ae-00224800449b', 'pdo_link'=> 'Scherzando-Hatshepsut/pedigree/34041/i',
      'sex'     => 'Dam', 'flag'    => '', 'colour'  => 'white and black', 'country' => 'United Kingdom',
      'type'    => 'working', 'kc_code' => 'KCSB 4162CY', 'dob'     => '2011-02-22', },
  ],
  map { [] } 1..14
);

$/=undef;

my @starter_trees = qw(38659 38655 15442 34041);

foreach my $n ( '38659', '38655', '15442', '34041' ) {
  my $tree =  get_tree( $n, 14 );
  foreach (1..14) {
    $results[$_+2]||=[];
    push @{$results[$_+2]}, @{$tree->[$_]};
  }
}
open my $ofh, '>', 'dogs.struct';
print {$ofh} Dumper( \@results );
close $ofh;

my %dogs;
my $c = 0;
foreach my $col (@results) {
  foreach (@{$col}) {
    $c++;
    $dogs{$_->{'pdo_link'}}[1] = $c;
    $dogs{$_->{'pdo_link'}}[0] ||= $c;
    $dogs{$_->{'pdo_link'}}[2] ||= $_->{'name'};
  }
}

my $previous;
my %ds;
foreach my $col (@results) {
  if( $previous ) {
    foreach (0..@{$previous}) {
      $ds{ $previous->[$_]{'pdo_link'} } ||= [ $previous->[$_]{'name'}, $col->[$_*2]{'pdo_link'}||  '-', $col->[$_*2]{'name'}  ||'SIRE',
                                                                        $col->[$_*2+1]{'pdo_link'}||'-', $col->[$_*2+1]{'name'}||'DAM' ];
    }
  }
  $previous = $col;
}


open my $d, '>', 'dogs.yarg';
my $trees_2 = {};
foreach ( keys %dogs ) {
  next unless 'SIRE' eq ($ds{$_}[2]||'SIRE');
  next unless 'DAM'  eq ($ds{$_}[4]||'DAM');
  next if D($dogs{$_}[0]) < 17;
  ## Now we need to look at the information about the dam and sire if we are missing the DAM/SIRE...
  my $id = $_ =~ m{/(\d+)/i$} ? $1 : '';
  next unless $id;
  my $tr = get_tree( $id, 14 );
  my $c = $dogs{$_}[1];
  foreach my $col (@results) {
    foreach (@{$col}) {
      $c++;
      $dogs{$_->{'pdo_link'}}[1] = $c;
      $dogs{$_->{'pdo_link'}}[0] ||= $c;
      $dogs{$_->{'pdo_link'}}[2] ||= $_->{'name'};
    }
  }

  $previous = [ {'pdo_link' => $_, 'name'=>$dogs{$_}[2]} ];
  delete $ds{$_};
  foreach my $c2 (@{$tr}) {
    foreach (0..@{$previous}) {
      $ds{ $previous->[$_]{'pdo_link'} } ||= [ $previous->[$_]{'name'}, $c2->[$_*2]{'pdo_link'}||  '-', $c2->[$_*2]{'name'}  ||'SIRE',
                                                                        $c2->[$_*2+1]{'pdo_link'}||'-', $c2->[$_*2+1]{'name'}||'DAM' ];
    }
  }
}
open $ofh, '>', 'dam-sire.txt';
foreach ( keys %ds ) {
  say {$ofh} join "\t", $_, @{%ds{$_}};
}
close $ofh;

open $ofh, '>', 'dogs.txt';
foreach (sort { $dogs{$a} <=> $dogs{$b} } keys %dogs) {
  printf {$ofh} "%3d %3d %3d\t%7d\t%7d\t%s\n", D($dogs{$_}[1])-D($dogs{$_}[0]), D($dogs{$_}[0]), D($dogs{$_}[1]), $dogs{$_}[0], $dogs{$_}[1], join "\t",
    $_,$dogs{$_}[2],$ds{$_}[1]||'-',$ds{$_}[2]||'SIRE',$ds{$_}[3]||'-',$ds{$_}[4]||'DAM';
}

sub get_tree {
  my( $fn, $size ) = @_;
  open my $fh, '<', 'source-files/ped-db/'.$fn.'.html';
  my $data = <$fh>;
  close $fh;
  $data=~s{.*<TABLE}{}ms;
  $data=~s{</TABLE>.*}{}ms;
  my @rows = split m{</TR>}, $data;
  pop @rows;
  my $cols = $size;
  my $T = 0;
  my $result_tree = [];
  foreach my $row (@rows) {
    my @cells = split m{<TD}msi, $row;
    shift @cells;
    my @cell_data = map { process($_) } @cells;
    my $c = $cols;
    foreach(reverse @cell_data){
      push @{$result_tree->[$c]}, $_;
      $c--;
      $T++;
    }
  }
  return $result_tree;
}

sub D {
  return length sprintf '%b', $_[0];
}

sub process {
  my $string = shift;
#print "*** $string ***";
  my( $link,$text ) = $string =~ m{<a[^>]+?href="([^"]+)"[^>]*>(.*?)</a>};
  unless( $link ) { ## No dog ..
    return {};
  }
  $link =~s{https://englishspringerspaniel.pedigreedatabaseonline.com/en/}{};
  my $sex           = $text   =~ m{fa-male} ? 'Sire' : 'Dam';
  my $flags         = join q( ), $text   =~ m{<rtitle>(.*?)</rtitle>}g;

  my $details       = $string   =~ m{<r2>(.*?)(?:<br>)?<p>} ? $1 : '';
  my @parts         = split m{(?:<br>|,)\s*}, $details;
  my $name          = $text =~ s{\s+<i class="fas fa-(?:fe)?male"></i>\s+}{}r
                            =~ s{\s*<rtitle>.*?</rtitle>\s*}{}r;
  return {
    'pdo_link' => $link,
    'name' => $name,
    'flags' => $flags,
    'sex'  => $sex,
    'info' => \@parts
  };
}
