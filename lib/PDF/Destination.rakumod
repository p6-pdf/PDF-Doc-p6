use v6;
use PDF::COS::Tie;
use PDF::COS::Tie::Array;

my subset NumNull where { ($_ // Numeric) ~~ Numeric };  #| UInt value or null

role PDF::Destination
    does PDF::COS::Tie::Array {

    # See [PDF 32000 Table 151 - Destination syntax]

    my enum Fit is export(:Fit) «
        :FitXYZoom<XYZ>     :FitWindow<Fit>
        :FitHoriz<FitH>     :FitVert<FitV>
        :FitRect<FitR>      :FitBox<FitB>
        :FitBoxHoriz<FitBH> :FitBoxVert<FitBV>
        »;

    use PDF::COS::Name;
    use PDF::COS::Tie::Hash;

    my subset PageLike of Hash where { .<Type> ~~ 'Page' }; # autoloaded PDF::Page
    my subset PageRef where PageLike|UInt|Pair;

    has PageRef $.page is index(0);
    has PDF::COS::Name $.fit is index(1);
    method is-page-ref { self[0] ~~ PageLike }

    multi sub is-dest-like(PageRef $page, 'XYZ', NumNull $left?,
                           NumNull $top?, NumNull $zoom?)          { True }
    multi sub is-dest-like(PageRef $page,)                         { True }
    multi sub is-dest-like(PageRef $page, 'Fit')                   { True }
    multi sub is-dest-like(PageRef $page, 'FitH', NumNull $top?)   { True }
    multi sub is-dest-like(PageRef $page, 'FitV', NumNull $left?)  { True }
    multi sub is-dest-like(PageRef $page, 'FitR', Numeric $left,
                           Numeric $bottom, Numeric $right,
                           Numeric $top )                          { True }
    multi sub is-dest-like(PageRef $page, 'FitB')                  { True }
    multi sub is-dest-like(PageRef $page, 'FitBH', NumNull $top?)  { True }
    multi sub is-dest-like(PageRef $page, 'FitBV', NumNull $left?) { True }
    multi sub is-dest-like(|c) is default                          { False }

    my subset DestinationLike of List is export(:DestinationLike) where is-dest-like(|$_);

    method delegate-destination(DestinationLike $_) {
        PDF::Destination[ .[1] ];
    }

    method !dest(List $dest) {
        my $role = $.delegate-destination($dest);
        $role.COERCE: $dest;
    }

    #| constructs a new PDF::Destination array object
    sub fit(Fit $f) { $f.value }
    multi method construct(FitWindow,  PageRef :$page!, )                { self!dest: [$page, fit(FitWindow), ] }
    multi method construct(FitHoriz,   PageRef :$page!, Numeric :$top )  { self!dest: [$page, fit(FitHoriz),    $top ] }
    multi method construct(FitVert,    PageRef :$page!, Numeric :$left ) { self!dest: [$page, fit(FitVert),     $left ] }
    multi method construct(FitBox,     PageRef :$page!, )                { self!dest: [$page, fit(FitBox),      ] }
    multi method construct(FitBoxHoriz,PageRef :$page!, Numeric :$top )  { self!dest: [$page, fit(FitBoxHoriz), $top] }
    multi method construct(FitBoxVert, PageRef :$page!, Numeric :$left ) { self!dest: [$page, fit(FitBoxVert),  $left] }

    multi method construct(FitXYZoom,  PageRef :$page!, Numeric :$left,
                           Numeric :$top, Numeric :$zoom )       { self!dest: [$page, fit(FitXYZoom), $left, $top, $zoom ] }

    multi method construct(FitRect,    PageRef :$page!,
                           Numeric :$left!,   Numeric :$bottom!,
                           Numeric :$right!,  Numeric :$top!, )  { self!dest: [$page, fit(FitRect),   $left,
                                                                                                      $bottom, $right, $top] }

    multi method construct(PageRef :$page!, )                    { self!dest: [$page, fit(FitWindow), ] }
    multi method construct(DestinationLike $dest) { self.construct(|$dest) }
    multi method construct(*@args) is default {
        fail "unable to construct destination: {@args.raku}";
    }

    # Coercions for explicit and named destinations
    # a named destination may be either a byte-string or name object
    my subset DestSpec is export(:DestSpec) where PDF::Destination|Str;
    proto sub coerce-dest($,$) is export(:coerce-dest) {*};

    # assume an array is a simple destination
    multi sub coerce-dest(DestinationLike $_, DestSpec) {
        my $role =  $?ROLE.delegate-destination($_);
        $role.COERCE: $_;
    }

    multi sub coerce-dest($_, DestSpec) is default {
        fail "Unable to handle destination: {.raku}";
    }

    # DestNamed coercement also allows an intermediate dictionary with a /D entry
    my role DestDict is export(:DestDict) does PDF::COS::Tie::Hash {
        has DestSpec $.D is entry(:required, :alias<destination>, :coerce(&coerce-dest));
    }

    my subset DestNamed is export(:DestNamed) where DestDict|DestSpec;
    multi sub coerce-dest(Hash $dict, DestNamed) {
        DestDict.COERCE($dict);
    }
    multi sub coerce-dest($_, DestNamed) {
        coerce-dest($_, DestSpec);
    }

}

role PDF::Destination['XYZ']
    does PDF::Destination {
    has Numeric $.left is index(2);
    has Numeric $.top is index(3);
    has Numeric $.zoom is index(4);
}

role PDF::Destination['Fit']
    does PDF::Destination {
}

role PDF::Destination['FitH']
    does PDF::Destination {
    has Numeric $.top is index(2);
}

role PDF::Destination['FitV']
    does PDF::Destination {
    has Numeric $.left is index(2);
}

role PDF::Destination['FitR']
    does PDF::Destination {
    has Numeric $.left is index(2);
    has Numeric $.bottom is index(3);
    has Numeric $.right is index(4);
    has Numeric $.top is index(5);
}

role PDF::Destination['FitB']
    does PDF::Destination {
}

role PDF::Destination['FitBH']
    does PDF::Destination {
    has Numeric $.top is index(2);
}

role PDF::Destination['FitBV']
    does PDF::Destination {
    has Numeric $.left is index(2);
}


