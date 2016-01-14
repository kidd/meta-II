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
                $string (?{say "io.write(", $^N, ")"}))*
              \s*
              \} (?{say 'io.write("\\n")'}) \s*
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
             | \( \s*  $choice \s* \)
             | \*  \s*  (?{say "repeat 	-- repetition --"})
               $primary(?{say "until not _switch 	-- repetition (end)"})
                     \s*  (?{say "_switch = true "})
           }xm;

$sequence = qr{
                (?{say"repeat	-- sequence"})
                (?:$primary (?{say "if not _switch then break end"})| $output)
                (?:\s+ $primary (?{say "if not _switch then break end"}) | \s+ $output)*
                (?{say"until true	-- sequence (end)"})
            }xm;

$choice = qr{   (?{say"repeat		-- choice --"})
                $sequence (?:\s* \| (?{say"if _switch then break end"}) \s* $sequence)*
                (?{say"until true	-- choice (end)"})
          }xm;

$rule = qr{
            $id (?{push(@stack, $^N); say("function ", $^N, "()")}) \s+
            = \s+
            $choice \s*
            ; (?{say "end -- (", (pop(@stack)), ')' })
        }xm;

$program = qr/ \.syntax \s+
               $id (?{ push(@stack, $^N); say('local _run = require("runtime")')}) \s+
               (?: $rule)* \s*
               \.end (?{say(pop(@stack), "()")})
             /mx;

# (".syntax bar
#   program = '.syntax' .id { 'local _run = require([[runtime]])' }  * rule '.end' ;
# .end" =~ /$program/);


my $bootstrap = q(
.syntax program

  output   = '{'
             * ( '$'      {'io.write(_input)'}
               | .string  {'io.write(' $  ')'})
             '}'          {'io.write("\\n")' };

  primary  = .id       { $ '()'                                }
           | .string   {'_run.testSTR(' $ ')'                  }
           | '.id'     {'local _input = _run.parseID()'        }
           | '.number' {'local _input = _run.parseNUM()'       }
           | '.string' {'local _input = _run.parseSTR()'       }
           | '.empty'  {'_switch = true'                       }
           | '(' choice ')'
           | '*'       {'repeat            -- repetition --'   }
             primary   {'until not _switch -- repetition (end)'}
                       {'_switch = true'                       };

  sequence = {'repeat            -- sequence   --'   }
               (primary {'if not _switch then break   end'} | output)
             * (primary {'if not _switch then error() end'} | output)
             {'until true        -- sequence   (end)'};

  choice   = {'repeat            -- choice     --'   }
             sequence * ('|' {'if _switch then break end'} sequence)
             {'until true        -- choice     (end)'};

  rule     = .id            {'function ' $ '()'}
             '=' choice ';' {'end -- ('  $ ')' };

  program  = '.syntax' .id {'local _run = require("runtime")'}
             * rule '.end' {$ '()'                           };

.end
);

($bootstrap =~ /$program/)


# ("'.syntax'" =~ /$primary/)
# print("DONE\n");

# while (chomp($_ = <>)){
#   /$program/xm;
# }
