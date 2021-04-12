use feature qw(say);
use strict;
use Data::Dumper qw(Dumper);
use Const::Fast qw(const);

const my $STARTER_GENERATIONS => 2;
const my $INITAL_FETCH        => 14;
const my $SUB_FETCH           => 12;

my  @results = initial_results_structure();

$/=undef;

my @starter_trees = map { $_->{'pdo_link'} =~ m{(\d+)} ? $1: () }
                    @{$results->[$STARTER_GENERATIONS]};

print Dumper(\@starter_trees);
exit;

foreach my $n ( @starter_trees ) {
  my $tree =  get_tree( $n, $INITIAL_FETCH );
  push @{$results[$_+2]}, @{$tree->[$_]} foreach 1..$INITIAL_FETCH;
}

## Write initial data to structure file on disk
open my $ofh, '>', 'dogs.struct'; print {$ofh} Dumper( \@results ); close $ofh;

my %dogs     = fetch_dog_positions( \@results );
my %parents  = fetch_parents(       \@results );


open my $d, '>', 'dogs.yarg';

foreach ( keys %dogs ) {
  next unless 'SIRE' eq ($parents{$_}{'sire_name'}||'SIRE');
  next unless 'DAM'  eq ($parents{$_}{'dam_name'} ||'DAM');
  next if depth( $dogs{$_}{'max'} ) <= $INITAL_FETCH + $STARTER_GENERATIONS;
  ## Now we need to look at the information about the dam and sire if we are missing the DAM/SIRE...
  my $id = $_ =~ m{/(\d+)/i$} ? $1 : '';
  next unless $id;
  my $tr = get_tree( $id, 14 );
  my $c  = $dogs{$_}[1];
  foreach my $col (@results) {
    foreach (@{$col}) {
      $c++;
      $dogs{$_->{'pdo_link'}}{'min'}  ||= $c;
      $dogs{$_->{'pdo_link'}}{'max'}    = $c;
      $dogs{$_->{'pdo_link'}}{'name'} ||= $_->{'name'};
    }
  }

  $previous = [ {'pdo_link' => $_, 'name'=>$dogs{$_}[2]} ];
  delete $parents{$_};
  foreach my $c2 (@{$tr}) {
    foreach (0..@{$previous}) {
      $parents{ $previous->[$_]{'pdo_link'} } ||= {
        'name'      => $previous->[$_]{'name'},
        'sire_link' => $c2->[$_*2]{'pdo_link'}   || '-',
        'sire_name' => $c2->[$_*2]{'name'}       || 'SIRE',
        'dam_link'  => $c2->[$_*2+1]{'pdo_link'} || '-',
        'dam_name'  => $c2->[$_*2+1]{'name'}     || 'DAM' ],
    };
  }
}

open $ofh, '>', 'dam-sire.txt';
say {$ofh} join "\t", $_, values %{%parents{$_}} foreach keys %ds;
close $ofh;

open $ofh, '>', 'dogs.txt';
foreach my $link ( sort { $dogs{$a} <=> $dogs{$b} } keys %dogs ) {
  printf {$ofh} "%3d %3d %3d\t%7d\t%7d\t%s\n",
    depth($dogs{$link}{'max'})-depth($dogs{$link}{'min'}),
    depth($dogs{$link}{'min'}), depth($dogs{$link}{'max'}),
    $dogs{$link}{'min'}, $dogs{$link}{'max'},
    join "\t",
      $link,                             $dogs{$link}{'name'},
      $parents{$link}{'sire_link'}||'-', $parents{$link}{'sire_name'}||'SIRE',
      $parents{$link}{'dam_link'} ||'-', $parents{$link}{'dam_name'} ||'DAM';
}
close $ofh;

## End of map function....

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

sub depth {
  return length sprintf '%b', $_[0];
}

sub process {
  my $string = shift;
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

sub initial_results_structure {
  return(
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
    map { [] } 1 .. $INITAL_FETCH
  );
}

sub fetch_dog_positions {
  my $res = shift;
  my $c   = 0;
  my %t_dogs = ();
  foreach my $col (@{$res}}) {
    foreach (@{$col}) {
      $c++;
      $t_dogs{ $_->{'pdo_link'} }{'max'}    = $c;
      $t_dogs{ $_->{'pdo_link'} }{'min'}  ||= $c;
      $t_dogs{ $_->{'pdo_link'} }{'name'} ||= $_->{'name'};
    }
  }
  return %t_dogs;
}

sub fetch_parents {
  my $res = shift;
  my $previous;
  my %ds;
  foreach my $col (@{$res}) {
    if( $previous ) {
      foreach (0..@{$previous}) {
        $ds{ $previous->[$_]{'pdo_link'} } ||= {
          'name'      => $previous->[$_]{'name'},
          'sire_link' => $col->[$_*2]{'pdo_link'}   || '-',
          'sire_name' => $col->[$_*2]{'name'}       || 'SIRE',
          'dam_link'  => $col->[$_*2+1]{'pdo_link'} || '-',
          'dam_name'  => $col->[$_*2+1]{'name'}     ||'DAM',
        };
      }
    }
    $previous = $col;
  }
  return %ds;
}

