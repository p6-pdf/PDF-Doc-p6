use v6;
use Test;

plan 20;

use PDF::Doc;
use PDF::IO::IndObj;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Grammar::PDF;
use PDF::Grammar::PDF::Actions;
use PDF::DAO;
use PDF::Content::Util::Font;

my $actions = PDF::Grammar::PDF::Actions.new;

my $input = q:to"--END-OBJ--";
7 0 obj <<
  /Type /Font
  /Subtype /Type1
  /Name /F1
  /BaseFont /Helvetica
  /Encoding /MacRomanEncoding
>> endobj
--END-OBJ--

PDF::Grammar::PDF.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed";
my %ast = $/.ast;
my $ind-obj = PDF::IO::IndObj.new( |%ast);
my $object = $ind-obj.object;
is $ind-obj.obj-num, 7, '$.obj-num';
is $ind-obj.gen-num, 0, '$.gen-num';
isa-ok $object, ::('PDF')::('Font::Type1');
is $object.Type, 'Font', '$.Type accessor';
is $object.Subtype, 'Type1', '$.Subype accessor';
is $object.Name, 'F1', '$.Name accessor';
is $object.BaseFont, 'Helvetica', '$.BaseFont accessor';
is $object.Encoding, 'MacRomanEncoding', '$.Encoding accessor';
is-json-equiv $ind-obj.ast, %ast, 'ast regeneration';

sub to-doc($font-obj) {
    my $dict = $font-obj.to-dict;
    { :$dict, :$font-obj }
}

my $hbi-afm = PDF::Content::Util::Font::core-font( :family<Helvetica>, :weight<Bold>, :style<Italic> );

my %params = to-doc($hbi-afm);
my $font = PDF::DAO.coerce( |%params );
isa-ok $font, ::('PDF::Font::Type1');
is $font.BaseFont, 'Helvetica-BoldOblique', '.BaseFont';
is $font.Encoding, 'WinAnsiEncoding', '.Encoding';
is-deeply $font.font-obj, $hbi-afm, '.font-obj';

my $zapf = PDF::Content::Util::Font::core-font( 'ZapfDingbats' );

%params = to-doc($zapf);
my $zapf-font = PDF::DAO.coerce( |%params );
isa-ok $zapf-font, ::('PDF::Font::Type1');
is $zapf-font.BaseFont, 'ZapfDingbats', '.BaseFont';
ok !$zapf-font.Encoding.defined, '!.Encoding';

my $sym = PDF::Content::Util::Font::core-font( 'Symbol' );

%params = to-doc($sym);
my $sym-font = PDF::DAO.coerce( |%params );
isa-ok $sym-font, ::('PDF::Font::Type1');
is $sym-font.BaseFont, 'Symbol', '.BaseFont';
ok !$sym-font.Encoding.defined, '!.Encoding';
is $sym-font.encode("ΑΒΓ").join, "ABG", '.encode(...)'; # /Alpha /Beta /Gamma
