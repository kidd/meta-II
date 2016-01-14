use strict;
use warnings;

sub say {
  print(@_, "\n");
}

our $program;
our $choice;
our $sequence;
our $primary;
our $rule;
our $id;
our $string;
our $output;
my $res;
$output = qr{
              \{ \s*
              (\$ (?{say "io.write(_input)"})
              |
                $string (?{say "io.write(", $^N, ")"})) \s*
              \} (?{say 'io.write("\\n")'})\s*
      }xm;

$string = qr{
              ('[^']*')
      }xm;

$id = qr{
          ([\w\d]+)
      }xm;

$primary = qr{
              $string (?{say "_run.testSTR($^N)"})
             |  $id     (?{say($^N, "()")})
             | \.id    (?{say "local _input = _run.parseID()"})
             | \.number (?{say "local _input = _run.parseNUM()"})
             | \.string(?{say "local _input = _run.parseSTR()"})
             | \.empty (?{say "_switch = true"})
             | \( $choice \)
             | \*  \s* (?{say "repeat 	-- repetition --"})
               $primary(?{say "until not _switch 	-- repetition (end)"})
                       (?{say "_switch = true "})
           }xm;

$sequence = qr{
                (?{say"repeat	-- sequence"})
                ($primary (?{say "if not _switch then break end"})| $output)
                (\s+ $primary (?{say "if not _switch then break end"}) | \s+ $output)*
                (?{say"until true	-- sequence (end)"})
            }xm;

$choice = qr{   (?{say"repeat		-- choice --"})
                $sequence (\s* \| (?{say"if _switch then break end"}) \s+ $sequence)*
                (?{say"until true	-- choice (end)"})
          }xm;

$rule = qr{
            $id (?{say("function ", $^N, "()")}) \s+
            = \s+
            $choice \s*
            ; (?{say "end -- (", $^N, ')' })
        }xm;

$program = qr/ .syntax \s+
               $id (?{say('local _run = require("runtime")')}) \s+
               ($rule)* \s*
               .end (?{say"$1()"})
             /mx;

(".syntax bar
  program = '.syntax' .id  ;
.end" =~ /$program/)

# ("'.syntax'" =~ /$primary/)
# print("DONE\n");

# while (chomp($_ = <>)){
#   /$program/xm;
# }
