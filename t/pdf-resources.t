use v6;
use Test;

use PDF::Doc;
use PDF::IO::IndObj;
use PDF::Doc::Type;
use PDF::Grammar::Test :is-json-equiv;
use PDF::Grammar::PDF;
use PDF::Grammar::PDF::Actions;

plan 64;
require ::('PDF::Catalog');
my $dict = { :Outlines(:ind-ref[2, 0]), :Type( :name<Catalog> ), :Pages{ :Type( :name<Pages> ) } };
my $catalog-obj = ::('PDF::Catalog').new( :$dict );

my $input = q:to"--END--";
16 0 obj <<
   /Type /Font
   /Subtype /TrueType
   /BaseFont /CourierNewPSMT
   /Encoding /WinAnsiEncoding
   /FirstChar 111
   /FontDescriptor 15 0 R
   /LastChar 111
   /Widths [ 600 ]
>> endobj
--END--

my $actions = PDF::Grammar::PDF::Actions.new;
my $grammar = PDF::Grammar::PDF;
$grammar.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed: $input";
my %ast = $/.ast;

# misc types follow

my $ind-obj = PDF::IO::IndObj.new( :$input, |%ast );
my $tt-font-obj = $ind-obj.object;
isa-ok $tt-font-obj, ::('PDF::Font::TrueType');
is $tt-font-obj.Type, 'Font', 'tt font $.Type';
is $tt-font-obj.Subtype, 'TrueType', 'tt font $.Subtype';
is $tt-font-obj.Encoding, 'WinAnsiEncoding', 'tt font $.Encoding';
is $tt-font-obj.type, 'Font', 'tt font type accessor';
is $tt-font-obj.subtype, 'TrueType', 'tt font subtype accessor';

require ::('PDF::Font::Type0');
$dict = { :BaseFont(:name<Wingdings-Regular>), :Encoding(:name<Identity-H>), :DescendantFonts[:ind-ref[15, 0]] };
my $t0-font-obj = ::('PDF::Font::Type0').new( :$dict );
is $t0-font-obj.Type, 'Font', 't0 font $.Type';
is $t0-font-obj.Subtype, 'Type0', 't0 font $.Subtype';
is $t0-font-obj.Encoding, 'Identity-H', 't0 font $.Encoding';

use PDF::Font::Type1;
class SubclassedType1Font is PDF::Font::Type1 {};
my $sc-font-obj = SubclassedType1Font.new( :dict{ :BaseFont( :name<Helvetica> ) } );
is $sc-font-obj.Type, 'Font', 'sc font $.Type';
is $sc-font-obj.Subtype, 'Type1', 'sc font $.Subtype';
is $sc-font-obj.BaseFont, 'Helvetica', 'sc font $.BaseFont';

my $enc-ast = :ind-obj[5, 2, :dict{ :Type( :name<Encoding> ), :BaseEncoding( :name<MacRomanEncoding> ) } ];
my $enc-ind-obj = PDF::IO::IndObj.new( |%($enc-ast) );
my $enc-obj = $enc-ind-obj.object;
isa-ok $enc-obj, ::('PDF::Encoding');
is $enc-obj.Type, 'Encoding', '$enc.Type';
is $enc-obj.BaseEncoding, 'MacRomanEncoding', '$enc.BaseEncoding';

my $objr-ast = :ind-obj[6, 0, :dict{ :Type( :name<OBJR> ), :Pg( :ind-ref[6, 1] ), :Obj( :ind-ref[6, 2]) } ];
my $reader = class { has $.auto-deref = False }.new;
my $objr-ind-obj = PDF::IO::IndObj.new( |%($objr-ast), :$reader );
my $objr-obj = $objr-ind-obj.object;
isa-ok $objr-obj, ::('PDF::OBJR');
is $objr-obj.Type, 'OBJR', '$objr.Type';
is-deeply $objr-obj<Pg>, (:ind-ref[6, 1]), '$objr<P>';
is-deeply $objr-obj<Obj>, (:ind-ref[6, 2]), '$objr<Obj>';

$input = q:to"--END--";
99 0 obj
<<
  /Type /OutputIntent  % Output intent dictionary
  /S /GTS_PDFX
  /OutputCondition (CGATS TR 001 (SWOP))
  /OutputConditionIdentifier (CGATS TR 001)
  /RegistryName (http://www.color.org)
  /DestOutputProfile 100 0 R
>> endobj
--END--

PDF::Grammar::PDF.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed: $input";
%ast = $/.ast;

$ind-obj = PDF::IO::IndObj.new( :$input, |%ast );
my $oi-font-obj = $ind-obj.object;
isa-ok $oi-font-obj, ::('PDF::OutputIntent');
is $oi-font-obj.S, 'GTS_PDFX', 'OutputIntent S';
is $oi-font-obj.OutputCondition, 'CGATS TR 001 (SWOP)', 'OutputIntent OutputCondition';
is $oi-font-obj.RegistryName, 'http://www.color.org', 'OutputIntent RegistryName';

use PDF::Page;
use PDF::XObject::Form;
use PDF::XObject::Image;
my $new-page = PDF::Page.new;
my $form1 = PDF::XObject::Form.new( :dict{ :BBox[0, 0, 100, 120] } );
my $fm1 = $new-page.use-resource( $form1 );
is-deeply $new-page.resource-key($fm1), 'Fm1', 'xobject form name';

my $form2 = PDF::XObject::Form.new( :dict{ :BBox[-3, -3, 103, 123] } );
my $image = PDF::XObject::Image.new( :dict{ :ColorSpace( :name<DeviceRGB> ), :Width(120), :Height(150) } );
my $fm2 = $new-page.use-resource( $form2 );
is-deeply $new-page.resource-key($fm2), 'Fm2', 'xobject form name';

my $im1 = $new-page.use-resource( $image );
is-deeply $new-page.resource-key($im1), 'Im1', 'xobject form name';

my $font = ::('PDF::Font::Type1').new: { :BaseFont<Helvetica> };
my $f1 = $new-page.use-resource( $font );
is-deeply $new-page.resource-key($f1), 'F1', 'font name';

is-json-equiv $new-page<Resources><XObject>, { :Fm1($form1), :Fm2($form2), :Im1($image) }, 'Resource XObject content';
is-json-equiv $new-page<Resources><Font>, { :F1($font) }, 'Resource Font content';

$input = q:to"--END--";
35 0 obj <<   % Graphics state parameter dictionary
  /Type /ExtGState
  /OP false
  /TR 36 0 R
>> endobj
--END--

$grammar.parse($input, :$actions, :rule<ind-obj>)
    // die "parse failed: $input";
%ast = $/.ast;

$ind-obj = PDF::IO::IndObj.new( :$input, |%ast, :$reader );
my $gs-obj = $ind-obj.object;
isa-ok $gs-obj, ::('PDF::ExtGState');
is $gs-obj.Type, 'ExtGState', 'ExtGState Type';
is-deeply $gs-obj.OP, False, 'ExtGState.OP';
lives-ok {$gs-obj<OP> = 42}, 'Typechecking setter bypass';
is-deeply $gs-obj<OP>, 42, 'Typechecking setter bypass';
dies-ok {$gs-obj.OP}, 'Typechecking on gettter';
lives-ok {$gs-obj.OP = False}, 'Type reassignment';
dies-ok {$gs-obj.OP = 42}, 'Typechecking on assignment';
is-deeply $gs-obj.OP, False, 'ExtGState.OP';
$gs-obj<OP> = False;
lives-ok {$gs-obj<OP> = True}, 'Valid property assignment';
is-deeply $gs-obj.OP, True, 'ExtGState.OP after assignment';
is $gs-obj.TR, (:ind-ref[36, 0]), 'ExtGState TR';

$gs-obj.transparency = .5;
is $gs-obj.CA, 0.5, 'transparency setter';
is $gs-obj.ca, 0.5, 'transparency setter';
lives-ok {$gs-obj.fill-alpha = .7}, 'transparency setter - alias';
is $gs-obj.fill-alpha, .7, 'transparency getter - alias';
is $gs-obj.stroke-alpha, .5, 'transparency getter - alias';
throws-like { $gs-obj.wtf }, X::Method::NotFound, 'ExtGState - unknown method';

$gs-obj.BG = {};
is-json-equiv $gs-obj.black-generation, {}, 'black-generation accessor';
$gs-obj.black-generation = PDF::DAO.coerce: :name<MyFunc>;
is $gs-obj.BG2, 'MyFunc', 'BG2 accessor';
ok !$gs-obj.BG.defined, 'BG accessor';
is $gs-obj.black-generation, 'MyFunc', 'black-generation accessor';

my $gs1 = $new-page.use-resource( $gs-obj );
is-deeply $new-page.resource-key($gs1), 'GS1', 'ExtGState resource entry';

use PDF::ColorSpace::Lab;
my $colorspace = PDF::ColorSpace::Lab.new;
isa-ok $colorspace, PDF::ColorSpace::Lab;
my $cs1 = $new-page.use-resource( $colorspace );
is $new-page.resource-key($cs1), 'CS1', 'ColorSpace resource entry';

use PDF::Shading::Axial;
my $Shading = PDF::Shading::Axial.new( :dict{ :ColorSpace(:name<DeviceRGB>),
							 :Function(:ind-ref[15, 0]),
							 :Coords[ 0.0, 0.0, 0.096, 0.0, 0.0, 1.0, 0],
							 },
				                   :$reader );
my $sh1 = $new-page.use-resource( $Shading );
is $new-page.resource-key($sh1), 'Sh1', 'Shading resource entry';

use PDF::Pattern::Shading;
my $pat-obj = PDF::Pattern::Shading.new( :dict{ :PaintType(1), :TilingType(2), :$Shading } );
my $pt1 = $new-page.use-resource( $pat-obj );
is $new-page.resource-key($pt1), 'Pt1', 'Shading resource entry';

my $resources = $new-page.Resources;
does-ok $resources, ::('PDF::Resources'), 'Resources type';

for qw<ExtGState ColorSpace Pattern Shading XObject Font> {
    lives-ok { $resources."$_"() }, "Resource.$_ accessor";
}

is-json-equiv $new-page.Resources, {
    :ExtGState{ :GS1($gs-obj) },
    :ColorSpace{ :CS1($colorspace) },
    :Pattern{ :Pt1($pat-obj) },
    :Shading{ :Sh1($Shading) },
    :XObject{ :Fm1($form1),
	      :Fm2($form2),
	      :Im1($image)},
    :Font{ :F1($font) },
}, 'Resources';
