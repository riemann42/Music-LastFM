#!/usr/bin/perl 

use strict;
use warnings;
use Pod::Abstract;
use Pod::Abstract::BuildNode qw(node);

use Moose;
use Data::Dumper;

use lib './';

sub docit {
    my $module = shift;
    my $req = $module;
    $req =~ s/::/\//g;
    $req .= '.pm';
    require $req;
    $module->import;
    my $meta = Class::MOP::Class->initialize($module);

    my %attributes= ();

    foreach my $attr ($meta->get_all_attributes) {
        #next if $attr->name =~ /^_/;
        $attributes{$attr->name} = $attr;
    }
    my $pa = Pod::Abstract->load_file($req);
    my @headings = $pa->select('/head1@heading');
    my $methods;
    foreach (@headings) {
        print STDERR $_->text(), "\n";
        if ($_->text() eq 'METHODS') {
            $methods = $_;
            last;
        }
    }
    unless ($methods) {
        die "Methods heading required";
    }
    my @defined = $methods->select('//item@label');
    foreach (sort keys %attributes) {
        my $skip = 0;
        foreach my $e (@defined) {
            if ($e =~ /\b$_\b/) {
                $skip++;
            }
        }
        unless ($skip) {
            my $attr = $attributes{$_};
            $methods->push(build_anode($attr));
        }
    }
    print $pa->pod;
}



sub build_anode {
    my $attr = shift;

    my $t = "";
    foreach (@{$attr->associated_methods}) {
        next if $_->name =~ /^_/;
        $t.= $_->name . " ";
    }

    if ( $attr->is_required) {
        $t .= 'REQUIRED';
    }

    my $item = node->item($t);

    my $p;

    if ($attr->is_default_a_coderef) {
        $p = "Default: Generated Automatically";
    }
    elsif ($attr->default){
        $p = "Default: ".$attr->default;
    }
    if ($p) {
        $item->push(node->paragraph($p));
    }
    $item->push(node->paragraph($attr->documentation || ""));
    return $item;
}


foreach (@ARGV) { 
    docit($_);
}
