use v6;

use PDF::Object::Array;
use PDF::Object::Tie;
use PDF::Object::Tie::Array;

class PDF::DOM::Type::ColorSpace
    is PDF::Object::Array {

    method type {'ColorSpace'}
    method subtype {$.Subtype}
    use PDF::Object::Name;
    use PDF::Object::Tie;
    has PDF::Object::Name $.Subtype is index(0);

    #| enforce tie-ins between self[0] & the class name. e.g.
    #| PDF::DOM::Type::ColorSpace::CalGray should have self[0] == 'CalGray'
    method cb-init {
        for self.^mro {
            my Str $class-name = .^name;

            if $class-name ~~ /^ 'PDF::DOM::Type::' (\w+) '::' (\w+) $/ {

		die "bad class-name $class-name"
		    unless ~$0 eq $.type;
		
                my Str $subtype = ~$1;

                if ! self.Subtype {
                    self.Subtype = PDF::Object.coerce( :name($subtype) );
                }
                else {
                    # /Type already set. check it agrees with the class name
                    die "conflict between class-name $class-name ($subtype) and array[0] type /{self[0]}"
                        unless self.Subtype eq $subtype;
                }
		self[1] //= { :WhitePoint[ 1.0, 1.0, 1.0 ] };
                last;
            }
        }
    }
}
