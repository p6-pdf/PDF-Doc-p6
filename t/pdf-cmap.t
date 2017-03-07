use v6;
use Test;

use PDF::Doc;
use PDF::Grammar::PDF;
use PDF::Grammar::PDF::Actions;
use PDF::IO::IndObj;

my $input = q:to"--END--";
22 0 obj <<
  /Type /CMap
  /CMapName /90ms-RKSJ-H
  /CIDSystemInfo <<
    /Registry (Adobe)
    /Ordering (Japan1)
    /Supplement 2
  >>
  /WMode 0
>> stream
%!PS-Adobe-3.0 Resource-CMap
%%DocumentNeededResources : ProcSet ( CIDInit )
...
endstream endobj
--END--

my $actions = PDF::Grammar::PDF::Actions.new;
PDF::Grammar::PDF.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed: $input";
my %ast = $/.ast;

my $ind-obj = PDF::IO::IndObj.new( :$input, |%ast );
my $cmap-obj = $ind-obj.object;
isa-ok $cmap-obj, ::('PDF::CMap');
is $cmap-obj.Type, 'CMap', 'CMap Type';
is $cmap-obj.CMapName, '90ms-RKSJ-H', 'CMapName';
is $cmap-obj.WMode, 0, 'WMode';
lives-ok {$cmap-obj.WMode = 1}, '$cmap.WMode setter - lives';
is $cmap-obj.WMode, 1, 'WMode';
isa-ok $cmap-obj.CIDSystemInfo, ::('PDF::CIDSystemInfo');
like $cmap-obj.decoded, rx/^'%!PS-Adobe-3.0 Resource-CMap'/, 'CMap stream content';

done-testing;