=pod

=head1 LICENSE

  Copyright (c) 1999-2013 The European Bioinformatics Institute and
  Genome Research Limited.  All rights reserved.

  This software is distributed under a modified Apache license.
  For license details, please see

  http://www.ensembl.org/info/about/code_licence.html

=head1 NAME

Parser - An abstract parser class

If you are extending this class you need to implement:
- open: opens stream
- close: closes stream
- read_block: reads a line/record/atomic piece of data, return scalar
- is_metadata: determines whether $self->{current_block} is metadata
- read_metadata: reads $self->{current_block}, stores relevant data in $self->{metadata} hash ref
- read_record: reads $self->{current_block}, possibly invoking $self->next_block(), stores list in $self->{record}
- a bunch of getters.

Optionally, you may want to implement:
- seek: seeks coordinate in sorted/indexed file

=cut

package Bio::EnsEMBL::IO::Parser;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw/;
use Bio::EnsEMBL::Utils::Scalar qw/assert_ref/;

=head2 new

    Constructor
    Argument [1+]: Hash of parameters for configuration, e.g. buffer sizes or 
                   specific functions for handling headers or data
    Returntype   : Bio::EnsEMBL::IO::Parser

=cut

sub new {
    my $class = shift;
    my %param_hash = @_;
    
    my $self = {
	    current_block     => undef,
	    waiting_block     => undef,
	    record            => undef,
	    metadata          => {},
	    params            => \%param_hash,
    	metadata_changed  => 0,
      strand_conversion => {'+' => '1', '.' => '0', '-' => '-1'},
    };

    # By default metadata is read and parsed
    if (not exists $self->{'params'}->{'must_parse_metadata'}) {
	    $self->{'params'}->{'must_parse_metadata'} = 1;
    }

    bless $self, $class;
    
    return $self;
}

=head2 shift_block

    Description: Wrapper for user defined functions 
                 Loads the buffered data as current, then stores a new block of data
                 into the waiting buffer.
    Returntype : Void

=cut

sub shift_block {
    my $self = shift;
    $self->{'current_block'} = $self->{'waiting_block'};
    $self->{'waiting_block'} = $self->read_block();
}

=head2 next_block

    Description: Wrapper for user defined functions 
                 Goes through the file blocks, either skipping or parsing metadata blocks
    Returntype : Void

=cut

sub next_block {
    my $self = shift;
    $self->shift_block();
    $self->{'metadata_changed'} = 0;
    while( defined $self->{'current_block'} && $self->is_metadata() ) {
      if ($self->{'params'}->{'mustParseMetadata'}) {
        $self->read_metadata();
	      $self->{'metadata_changed'} = 1;
      }
      $self->shift_block();
    }
}

=head2 next

    Description: Business logic of the iterator
                 Reads blocks of data from the file, determines whether they contain 
                 metadata or an actual record, optionally processes the metadata, and
                 terminates when a record has been loaded.
    Returntype : True/False depending on whether a record was found.

=cut

sub next {
    my $self = shift;

    $self->{'record'} = undef;
    $self->next_block();

    if (defined $self->{'current_block'}) {
        $self->read_record();
        return 1;
    } else {
        return 0;
    }
}

=head2 metadataChanged 

    Description: whether metadata was changed since the previous record
    Returntype : Boolean 

=cut

sub metadataChanged {
    my $self = shift;
    return $self->{'metadata_changed'};
}

=head2 seek

    Description: Placeholder for user-defined seek function.
                 Function must allow the user to request that all the subsequent 
                 records be part of a given genomic region.
    Returntype : Void

=cut

sub seek {
    throw("Method not implemented. Might not be applicable to your file format.");
}

=head2 read_block

    Description: Placeholder for user-defined IO function.
                 Function must obtain and store the next block (e.g. line) of data from
                 the file.
    Returntype : Void 

=cut

sub read_block {
    throw("Method not implemented. This is really important");
}

=head2 is_metadata

    Description: Placeholder for user-defined metadata function.
                 Function must determine whether $self->{'current_block'}
                 contains metadata or not.
    Returntype : Boolean

=cut

sub is_metadata {
    throw("Method not implemented. This is really important");
}

=head2 read_metadata

    Description: Placeholder for user-defined metadata function.
                 Function must go through $self-{'current_block'},
                 extract relevant metadata, and store it in 
                 $self->{'metadata'}
    Returntype : Boolean

=cut

sub read_metadata {
    throw("Method not implemented. This is really important");
}

=head2 read_record

    Description: Placeholder for user-defined record lexing function.
                 Function must pre-process the data in $self->current block so that it is
                 readily available to accessor methods.
    Returntype : Void 

=cut

sub read_record {
    throw("Method not implemented. This is really important");
}

=head2 open

    Description: Placeholder for user-defined filehandling function.
                 Function must prepare input streams.
    Returntype : True/False on success/failure

=cut

sub open {
    throw("Method not implemented. This is really important");
}


=head2 close

    Description: Placeholder for user-defined filehandling function.
                 Function must close all open input streams.
    Returntype : True/False on success/failure

=cut

sub close {
    throw("Method not implemented. This is really important");
}

=head2 close

    Description: Wrapper function to demand format as a parameter
    Returntype : Parser object

=cut

sub open_as {
    my ($format, @other_args) = @_;
    if ($format eq 'bed') {
        return Bio::EnsEMBL::IO::Parser::Bed(@other_args);
    } elsif ($format eq 'bigBed') {
        return Bio::EnsEMBL::IO::Parser::BigBed(@other_args);
    } elsif ($format eq 'bigWig') {
        return Bio::EnsEMBL::IO::Parser::BigWig(@other_args);
    } elsif ($format eq 'EMF') {
        return Bio::EnsEMBL::IO::Parser::EMF(@other_args);
    } elsif ($format eq 'fasta') {
        return Bio::EnsEMBL::IO::Parser::Fasta(@other_args);
    } elsif ($format eq 'gff3') {
        return Bio::EnsEMBL::IO::Parser::GFF3(@other_args);
    } elsif ($format eq 'gvf') {
        return Bio::EnsEMBL::IO::Parser::GVF(@other_args);
    } elsif ($format eq 'psl') {
        return Bio::EnsEMBL::IO::Parser::PSL(@other_args);
    } elsif ($format eq 'wig') {
        return Bio::EnsEMBL::IO::Parser::Wig(@other_args);
    }
}

1;
