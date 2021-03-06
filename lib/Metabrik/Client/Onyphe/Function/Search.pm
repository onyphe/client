#
# $Id$
#
package Metabrik::Client::Onyphe::Function::Search;
use strict;
use warnings;

use base qw(Metabrik::Client::Onyphe::Function);

sub brik_properties {
   return {
      revision => '$Revision: d629ccff5f0c $',
      tags => [ qw(client onyphe) ],
      author => 'ONYPHE <contact[at]onyphe.io>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         run => [ qw(page state search) ],
      },
   };
}

sub run {
   my $self = shift;
   my ($page, $state, $search) = @_;

   $self->brik_help_run_undef_arg('run', $page) or return;
   $self->brik_help_run_undef_arg('run', $search) or return;

   my $cb = sub {
      my ($this, $state, $new, $search) = @_;

      my $copy = $search;
      my (@holders) = $copy =~ m{[\w\.]+\s*:\s*\$([\w\.]+)}g;

      # Update where clause with placeholder values
      my %searches = ();
      for my $holder (@holders) {
         my $values = $self->value_as_array($this, $holder);
         for my $value (@$values) {
            while ($copy =~
               s{(\S+)\s*:\s*\$$holder}{$1:$value}) {
            }
            $searches{$copy}++;  # Make them unique
         }
      }

      my @searches = keys %searches;
      for my $search (@searches) {
         $self->log->verbose("search[$search]");
         my $this_page = $self->search($search, 1, 1) or return;
         if (defined($this_page->{count}) && $this_page->{count} > 0) {
            # Keep this page results if matches were found.
            push @$new, @{$this_page->{results}};
         }
      }

      return 1;
   };

   return $self->iter($page, $cb, $state, $search);
}

1;
