use strict;
use warnings;

sub say {
  print(@_, "\n");
}

our @stack = ();

our $program;
our $choice;
our $sequence;
our $primary;
our $rule;
our $id;
our $string;
our $output;
my $res;

$string = qr{
              ('[^']*')
      }xm;

$output = qr{
              \{ \s*
              (?: \s*
                \$ (?{say "io.write(_input)"})
              |
                \s* $string (?{say "io.write(", $^N, ")"})
              )*
              \s*
              \} (?{say 'io.write("\\n")'}) \s*
      }xm;


$id = qr{
          ([\w][\w\d]*)
      }xm;

$primary = qr{
               (?: $string  (?{say "_run.testSTR($^N)"})
               |  $id     (?{say($^N, "()")})
               | \.id    (?{say "local _input = _run.parseID()"})
               | \.number (?{say "local _input = _run.parseNUM()"})
               | \.string (?{say "local _input = _run.parseSTR()"})
               | \.empty (?{say "_switch = true"})
               | \( \s*  (??{our $choice}) \s* \)
               | \*  \s*  (?{say "repeat 	-- repetition --"})
                  (??{our $primary}) (?{say "until not _switch 	-- repetition (end)"})
                     \s*  (?{say "_switch = true "}))
           }xm;

$sequence = qr{ \s*
                (?{say"repeat	-- sequence"})
                (?: $primary (?{say "if not _switch then break end"})| $output)
                (?: \s* (?:  $primary (?{say "if not _switch then error()  end"}) | $output ))*
                (?{say"until true	-- sequence (end)"})
            }xm;

$choice = qr{   (?{say"repeat		-- choice --"})
                $sequence (?:\s* \| (?{say"if _switch then break end"}) \s* $sequence)* \s*
                (?{say"until true	-- choice (end)"})
          }xm;

$rule = qr{
            $id (?{push(@stack, $^N); say("function ", $^N, "()")}) \s+
            = \s+
            $choice \s*
            ; (?{say "end -- (", (pop(@stack)), ')' })
        }xm;

$program = qr/^ \.syntax \s+
               $id (?{ push(@stack, $^N); say('local _run = require("runtime")')}) \s+
               (?: \s* $rule)* \s*
               \.end (?{say(pop(@stack), "()")})
             $/mx;

my $bootstrap;
my $a;
if ($a=shift){
  local $/=undef;
  open FILE, $a or die "Couldn't open file: $!";
  $bootstrap= <FILE>;
  close FILE;
}

($bootstrap =~ /$program/)
