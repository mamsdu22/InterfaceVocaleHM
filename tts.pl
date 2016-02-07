#!/usr/bin/perl


use strict;
use warnings;
use Switch;

use File::Basename;

use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use open qw(:std :utf8);

use Getopt::Long qw(:config no_ignore_case);

use File::Find qw(finddepth);

use File::Temp qw/ tempfile /;

use List::MoreUtils 'any';

use Data::Dumper;

use File::Copy;

#############################################################
my $scriptDirectory = dirname( __FILE__ )."/tts-subprocess/";
my $PERL_EXEC = "perl";

my $rootsLabel_wordSeq          = 'Word';
my $rootsLabel_wordPhnSeq       = 'Word Phn';
my $rootsLabel_wordPosSeq       = 'Word Pos';
my $rootsLabel_graphemeSeq      = 'Grapheme';
my $rootsLabel_graphemePhnSeq   = 'Grapheme Phn';
my $rootsLabel_posSeq           = 'Pos';
my $rootsLabel_phnSeq           = 'Phoneme';
my $rootsLabel_phnConfSeq       = 'Phoneme Confidence';
my $rootsLabel_nssSeq           = 'NSS';
my $rootsLabel_fillerSeq        = 'Filler';
my $rootsLabel_orderSeq         = 'Ordering';
my $rootsLabel_slbSeq           = 'Syllable';
my $rootsLabel_durSeq           = 'Predicted Signal Segment';

my $rootsLabel_usrphnSeq        = 'Phoneme User';
my $rootsLabel_orderTextSeq     = 'Ordering Text';
my $rootsLabel_usrDurationSeq   = 'Duration User';

# WARNING: order is important in the following arrays
my @STANDARD_STEPS = ("linguistics", "phonetization", "syllabification", "synthesis preparation", "alphabet restriction", "duration");
my @ALL_STEPS = ("load", "data preparation", @STANDARD_STEPS, "synthesis", "prosody", "save");

my $KEEP_ALL = 0; # remove tmp file and dir;

#############################################################

sub read_config {
	my $file = shift;
	my $p_hash = shift;
	open(F, "$file");
	while (<F>) {
		chomp;
		my ($arg,$value) = $_ =~ /^(.*?)[\t =](.*)$/;
		$$p_hash{$arg} = $value;
	}
	close(F);
}

my $OPT_HELP = 0;
my $OPT_CHECK = 0;
my $OPT_COMMAND_ONLY = 0;
my $OPT_VERBOSE = 0;
my $OPT_DEBUG = 0;
my $OPT_START = "";
my $OPT_STOP = "";
my $OPT_XML = 0;
my $OPT_UTTERANCE_INDEX = -1;
my $OPT_SPLIT_UTTERANCES = 0;
my $OPT_LANGUAGE = "fr";
my $OPT_STANFORD = 1;
my $OPT_SYNAPSE = 0;
my $OPT_USE_VOXYGEN = 0;
my $OPT_USE_ESPEAK = 0;
my $OPT_USE_ESPEAK_MONOPHTHONGS = 0;
my $OPT_USE_GRUMPH = 0;
my $OPT_GRUMPH_N_PRON = 1;
my $OPT_GRUMPH_I_PRON = 0;
my $OPT_GRUMPH_CONFIG_FILE = "";
my $DUR_NETWORK = "";
my $weightFile = "";
my $weightPolicy = "";
my $alphabet = "liaphon";
my $nssAlphabet = "liaphon";
my $flagPitch = 0;
my $flagDuration = 0;
my $lengthmax = 3;
my $durMin = "";
my $sharedName = "";#corpus;
my $corpusConf = "";
my $outputCsv = "";
my $algorithm = "Astar";
my $stopMode = "best";
my $requiredPath = 1;
my $minCost = -1.0;
my $maxCost = -1.0;
my $maxPath = 1;
my $flagNoFilters = 0;
my $viterbiMaxHeap = -1;
my $tmpDir = "/tmp";
my $flagReversedCost = 0;
my $flagPmkfile = 0;
my $flagLabfile = 0;
my $confFilters = "";
my $contextSize = -1;
my $flagHardSandwich = 0;
my $flagFuzzySandwich = 0;
my $fuzzySandwichConfig = undef;
my $defaultPauseDuration = 250;

my $ftargetCost = 0;
my $targetCostFile = "";

my @filters = ();

my $pitchFactor = undef;
my $durationFactor = undef;
my $prosodyFile = undef;
my $f0min = undef;
my $f0max = undef;

my $durationLogFlag = 0;

my $weightTC = 1;
my $weightCC = 1;
my $candidates_threshold = 0;
my $ccostThreshold = undef;
my $freq = undef; #44100;
my $flagProsodyCorrection = 0;

my $alphabetFile = "";
#############################################################

sub usage()
{
my $steps = join("; ", @ALL_STEPS);
print <<EOF;
________________________________________________
  Usage:
    perl $0 [options] inputFile outputFile

  Synopsis:
    Either shared or config options must be present.

  Options:
    --help           -h       \t\tPrint this message ;-).
    --verbose        -v       \t\tPrint debug information.
    --tmp-dir        -t       \t\tTemp directory (default is $tmpDir).
    --keep-files     -k       \t\tKeep temporary files (if any after the script run)
    --check          -c       \t\tCheck if generation path is compatible
    --xml                     \t\tUse a SSML file in input
    --start                   \t\tStep at which the process should be started. Known steps are: $steps.
                              \t\tNOTICE: the input file should be adapted accordingly.
    --stop                    \t\tStep at which the process should be stopped. Known steps are: $steps.
                              \t\tNOTICE: the output file should be adapted accordingly.
    --command-only            \t\tOnly prepare and display the command. Do not run it.
    --utterance <i>  -a       \t\tOnly consider the given utterance in the corpus instead of all utterances (default:-1, meaning "all utterances").
    
    --word-sequence <s>       \t\tName of the word sequence (default is $rootsLabel_wordSeq)
    --word-phn-sequence <s>   \t\tName of the word sequence as used by the phonetizer (default is $rootsLabel_wordPhnSeq)
    --word-pos-sequence <s>   \t\tName of the word sequence as used by the POS tagger (default is $rootsLabel_wordPosSeq)
    --grapheme-sequence <s>   \t\tName of the grapheme sequence (default is $rootsLabel_graphemeSeq)
    --grapheme-phn-sequence <s>\t\tName of the grapheme sequence as used by the phonetizer (default is $rootsLabel_graphemePhnSeq)
    --pos-sequence <s>        \t\tName of the POS sequence (default is $rootsLabel_posSeq)
    --phoneme-sequence <s>    \t\tName of the phoneme sequence (default is $rootsLabel_phnSeq)
    --phoneme-confidence-sequence <s>\tName of the sequence of confidence values on the phoneme sequence (default is $rootsLabel_phnConfSeq)
    --phoneme-user-sequence <s>    \tName of the user's phoneme sequence (default is $rootsLabel_usrphnSeq)
    --nss-sequence <s>        \t\tName of the non speech sound sequence (default is $rootsLabel_nssSeq)
    --filler-sequence <s>     \t\tName of the filler sequence (default is $rootsLabel_fillerSeq)
    --ordering-sequence <s>   \t\tName of the ordering sequence on phonemes and non speech sounds (default is $rootsLabel_orderSeq)
    --ordering-text-sequence <s>   \tName of the ordering sequence on the input text (default is $rootsLabel_orderTextSeq)
    --syllable-sequence <s>   \t\tName of the syllable sequence (default is $rootsLabel_slbSeq)
    --duration-sequence <s>   \t\tName of the sequence of durations for the predicted signal segment (default is $rootsLabel_durSeq)
    --duration-user-sequence <s>   \tName of the duration sequence as given by the user (default is $rootsLabel_usrDurationSeq)
    
    --split-utterances    \t\tSplit the utterance into different wave files
    --language <s>        \t\tLanguage for synthesis (default:"fr") [fr|en]
    --stanford            \t\tUse Stanford's POS tagger (default)
    --synapse             \t\tUse Synapse's POS tagger
    --voxygen             \t\tUse voxygen phonetizer
    --espeak              \t\tUse eSpeak phonetizer
    --espeak-monophthongs \t\tUse monophthongs output by eSpeak
    --grumph              \t\tUse Grumph phonetizer
    --grumph-n-pron <i>   \t\tNumber of pronunciations to be generated by Grumph (default is $OPT_GRUMPH_N_PRON)
    --grumph-i-pron <i>   \t\tIndex of the pronunciations to be used for synthesis (default is $OPT_GRUMPH_I_PRON)
    --grumph-conf <s>     \t\tConfiguration file for Grumph
    --alphabet <s>	-a    \t\tName of the alphabet to use with the corpus (default: "liaphon")
    --nss-alphabet <s>	  \t\tName of the NSS alphabet to use with the corpus (default: "liaphon")
    --alphabet-file <s>   \t\tName of the file containing the restrited alphabet

    --default-duration   \t\tDefault pause duration in ms [250]
    --duration	          \t\tUse duration prediction
    --duration-network <s> \t\tPath to the file containing the neural network predicting phonemes duration
    --context-size <i>	\t\tContext size for Neural network predictions (must match --duration-network file value)
    --duration-log	\t\tLog duration prediction
    --frequency <i>     \t\tProvide the sampling frequency of the TTS corpus [44100] (TODO: option should be removed in the future or automated)
    
    --weight-file <s>   \t\tPath to the file containing weights for the cost function
    --weight-policy <s>	\t\tThe name of the weight policy to use (depends on the weight file, usually "Smoothing")
    --pitch             \t\tUse a pitch constraint
    --length|-s <i>     \t\tSpecify max length for units (default is 3)
    --ph-dur-min <i>    \t\tSpecify min duration for units (no min)
    --shared <s>	\t\tGive the name of the shared corpus (default: "")
    --config <s>        \t\tGive the name of the corpus config file (default: "")
    --path-file <s>     \t\tWrite a csv file with the path data
    --algorithm <s>     \t\tUse the specified algorithm for unit selection [Astar|Viterbi] (default is Astar)
    --heap-max <i>      \t\tMax size for Viterbi heaps
    
    --stop-mode <s>     \t\tAstar stop mode [first](first|best|pathlist|pathno)
    --required-path <i> \t\tIndex of the path to produce in the path ranking (with path no stop mode) [1]
    --min-cost <f>      \t\tMinimum cost value [-1.0]
    --max-cost <f>      \t\tMaximum cost value [-1.0]
    --max-path <i>      \t\tMaximum number of paths (with pathlist stop mode) [1]
    --no-filter         \t\tDesactivate the pre-selection filters
    --reversed-cost     \t\tReverse the cost function to find the worst path.
    --filter-configuration <s>  \tProvide a configuration file for configuring the preselection filters (target cost).
    --add-filter <s>	\t\t(multi) Add a preselection filter
    --weight-tc <f>	\t\tCustomize the target cost/concatenation cost weighting (target cost)
    --weight-cc <f>	      \t\tCustomize the target cost/concatenation cost weighting (concatenation cost)
    --candidates-threshold <i> \t\tNumber of candidate nodes before relaxing filters
    --ccost-threshold <f> \t\tThreshold on concatenation cost above which filters are relaxed
    --sandwich            \t\tUse hard sandwich cost
    --fuzzy-sandwich      \t\tUse fuzzy sandwich cost
    --fuzzy-sandwich-config=s\t\tUse fuzzy sandwich cost config file	
    --filters-target-cost \t\tUse filters in the target cost
    --filters-target-cost-file <s> \t

    --pitch-factor <f>  \t\tGlobal pitch modification factor [1.0]
    --duration-factor <f> \t\tGlobal duration modification factor [1.0]
    --prosody-file <s>  \t\tFile containing pitch and duration factors as sequences
    --f0-min <i>        \t\tMinimum value for F0
    --f0-max <i>        \t\tMaximum value for F0
    --buildlab          \t\tBuild a lab file with the generated wav
    --buildpmk          \t\tBuild a file containing pitchmarks in the generated wav
    --prosody-correction \t\tAdjust prosody to predicted values
________________________________________________
EOF
}


GetOptions (
    'keep-files|k'      => \$KEEP_ALL,
    'help|h'            => \$OPT_HELP,
    'check|c'           => \$OPT_CHECK,
    'command-only'      => \$OPT_COMMAND_ONLY,
    'verbose|v'         => \$OPT_VERBOSE,   
    'debug|d'           => \$OPT_DEBUG,   
    'xml'               => \$OPT_XML,
    'start=s'           => \$OPT_START,
    'stop=s'            => \$OPT_STOP,
    'utterance|u=i'     => \$OPT_UTTERANCE_INDEX,
    'split-utterances'  => \$OPT_SPLIT_UTTERANCES,
	
    'word-sequence=s' =>               \$rootsLabel_wordSeq,
    'word-phn-sequence=s' =>           \$rootsLabel_wordPhnSeq,
    'word-pos-sequence=s' =>           \$rootsLabel_wordPosSeq,
    'grapheme-sequence=s' =>           \$rootsLabel_graphemeSeq,
    'grapheme-phn-sequence=s' =>       \$rootsLabel_graphemePhnSeq,
    'pos-sequence=s' =>                \$rootsLabel_posSeq,
    'phoneme-sequence=s' =>            \$rootsLabel_phnSeq,
    'phoneme-confidence-sequence=s' => \$rootsLabel_phnConfSeq,
    'phoneme-user-sequence=s' =>       \$rootsLabel_usrphnSeq,
    'nss-sequence=s' =>                \$rootsLabel_nssSeq,
    'filler-sequence=s' =>             \$rootsLabel_fillerSeq,
    'ordering-sequence=s' =>           \$rootsLabel_orderSeq,
    'ordering-text-sequence=s' =>      \$rootsLabel_orderTextSeq,
    'syllable-sequence=s' =>           \$rootsLabel_slbSeq,
    'duration-sequence=s' =>           \$rootsLabel_durSeq,
    'duration-user-sequence=s' =>      \$rootsLabel_usrDurationSeq,
	
    'language=s'        => \$OPT_LANGUAGE,
    'stanford'          => \$OPT_STANFORD,
    'synapse'           => \$OPT_SYNAPSE,
    'voxygen'           => \$OPT_USE_VOXYGEN,
	'espeak'            => \$OPT_USE_ESPEAK,
	'espeak-monophthongs' => \$OPT_USE_ESPEAK_MONOPHTHONGS,
    'grumph'            => \$OPT_USE_GRUMPH,
    'grumph-n-pron=i'   => \$OPT_GRUMPH_N_PRON,
	'grumph-i-pron=i'   => \$OPT_GRUMPH_I_PRON,
    'grumph-config=s'   => \$OPT_GRUMPH_CONFIG_FILE,
    'duration-network=s'=> \$DUR_NETWORK,
    'weight-file=s'     => \$weightFile,
    'weight-policy=s'   => \$weightPolicy,
    'alphabet|a=s'      => \$alphabet,
    'nss-alphabet=s'      => \$nssAlphabet,
    'alphabet-file=s'      => \$alphabetFile,	
	'default-duration=i'=> \$defaultPauseDuration,
    'duration'          => \$flagDuration,
    'pitch'             => \$flagPitch,
    'length|s=i'        => \$lengthmax,
    'ph-dur-min=i'      => \$durMin,
    'shared=s'          => \$sharedName,
    'config=s'          => \$corpusConf,
    'path-file=s'       => \$outputCsv,
    'algorithm=s'       => \$algorithm,
    'stop-mode=s'       => \$stopMode,
    'required-path=i'   => \$requiredPath,
    'min-cost=f'        => \$minCost,
    'max-cost=f'        => \$maxCost,
    'weight-tc=f'       => \$weightTC,
    'weight-cc=f'       => \$weightCC,
    'candidates-threshold=i' => \$candidates_threshold,
	'filters-target-cost' => \$ftargetCost,
	'filters-target-cost-file=s' => \$targetCostFile,
    'frequency=i'       => \$freq,
    'prosody-correction'=> \$flagProsodyCorrection,
	'sandwich'          => \$flagHardSandwich,
	'fuzzy-sandwich'    => \$flagFuzzySandwich,
	'fuzzy-sandwich-config=s'    => \$fuzzySandwichConfig,	
	'ccost-threshold=f' => \$ccostThreshold,

    'max-path=i'        => \$maxPath,
    'heap-max=i'        => \$viterbiMaxHeap,
    'no-filter'         => \$flagNoFilters,
    'reversed-cost' 	  => \$flagReversedCost,
    'add-filter=s'		  => \@filters,
    'context-size=i'    => \$contextSize,
    'duration-log'    	=> \$durationLogFlag,

    'buildlab'          => \$flagLabfile,
    'buildpmk'          => \$flagPmkfile,

    'pitch-factor=f'    => \$pitchFactor,
    'duration-factor=f' => \$durationFactor,
    'prosody-file=s'    => \$prosodyFile,
    'f0-min=i'          => \$f0min,
    'f0-max=i'          => \$f0max,

    'tmp-dir|t=s'         => \$tmpDir,
    );

die usage if(@ARGV != 2 || $OPT_HELP);

if($sharedName eq "" && $corpusConf eq "")
{
    die "Either shared or config options must be present.";
}

if ($OPT_SYNAPSE) {
	$OPT_STANFORD = 0;
}

my %grumph_config;
if ($OPT_USE_GRUMPH) {
	if ($OPT_GRUMPH_I_PRON >= $OPT_GRUMPH_N_PRON) {
		die("Cannot ask for a prononuciation over the number of generated pronunciations.\n");
	}
	if ($OPT_GRUMPH_CONFIG_FILE eq "") {
		die("No configuration file provided for phonetizer Grumph.\n");
	}
	else {
		read_config($OPT_GRUMPH_CONFIG_FILE, \%grumph_config);
	}
}

my ($inputFile, $outputFile)  = @ARGV;
my ($inputBaseFilename, $inputDirectory, $inputFormat) =  fileparse($inputFile, qr/\.[^.]*/);
my ($outputBaseFilename, $outputDirectory, $outputFormat) =  fileparse($outputFile, qr/\.[^.]*/);

my $flagModifyProsody = 0;
$flagModifyProsody = 1 if((defined $pitchFactor) || (defined $durationFactor) || (defined $prosodyFile) || ($flagProsodyCorrection));

my $flagCreateDurationLog = ($durationLogFlag || $flagProsodyCorrection);
my $flagCreateLabFile = ($flagLabfile || $flagProsodyCorrection);
my $flagCreatePmkFile = ($flagPmkfile || $flagProsodyCorrection);

my $flagDeleteDurationLog = ($flagCreateDurationLog && !$durationLogFlag);
my $flagDeleteLabFile = ($flagCreateLabFile && !$flagLabfile);
my $flagDeletePmkFile = ($flagCreatePmkFile && !$flagPmkfile);


if ($OPT_LANGUAGE ne "fr" && $OPT_LANGUAGE ne "en") {
	die("Language not supported [$OPT_LANGUAGE].\n");
}


my $OPT_useLiaphon = !$OPT_USE_VOXYGEN && !$OPT_USE_GRUMPH && !$OPT_USE_ESPEAK;


############################################################
# Preparation of steps
############################################################

sub get_step_index {
	my $step = shift;
	for (my $index = 0; $index < @ALL_STEPS; $index++) {
		if ($ALL_STEPS[$index] eq $step) { return $index; }
	}
	return -1;
}

my @steps = ();

my $start = ($OPT_START eq ""?1:0);
my $stop = 0;
for (my $i = 0; $i < @STANDARD_STEPS && !$stop; $i++) {
	if ($STANDARD_STEPS[$i] eq $OPT_START) { $start = 1; }
	if ($start) { push(@steps, $STANDARD_STEPS[$i]); }
	if ($STANDARD_STEPS[$i] eq $OPT_STOP) { $stop = 1; }
}

# Optionnaly, select the target utterance
if ($OPT_UTTERANCE_INDEX > -1) {
	unshift(@steps, "select utterance");
}

if ($OPT_START eq "") { unshift(@steps, "data preparation"); }
elsif (!any { /^$OPT_START$/ } @ALL_STEPS ) {
	die("Unknown first step \"$OPT_START\". Allowed steps are: ".join("; ", @ALL_STEPS).".\n");
}
else { unshift(@steps, "load"); }

if ($OPT_STOP eq "") { push(@steps, "synthesis"); }
elsif (!any { /^$OPT_STOP$/ } @ALL_STEPS ) {
	die("Unknown last step \"$OPT_STOP\". Allowed steps are: ".join("; ", @ALL_STEPS).".\n");
}
else { push(@steps, "save"); }

my @commands = ();
my @PostActions = ();



############################################################

# Shared variables across steps
my $durationLogFilename = "";
my $syntOutputBaseFilename = "";
my $labFilename = "";
my $pmkFilename = "";


foreach my $current_step (@steps) {
	switch ($current_step) {

		############################
		# Prepare data
		case "data preparation" {
			
			my $prepare_std = $PERL_EXEC." ".$scriptDirectory."/10-prepare-text.pl ";
			$prepare_std .= " -g \"$rootsLabel_graphemeSeq\" ";
			$prepare_std .= " -w \"$rootsLabel_wordSeq\" ";
			$prepare_std .= " -p \"$rootsLabel_usrphnSeq\" ";
			$prepare_std .= " -o \"$rootsLabel_orderTextSeq\" ";
			$prepare_std .= " -i \"$rootsLabel_fillerSeq\" ";
			$prepare_std .= " -d \"$rootsLabel_usrDurationSeq\" ";
			$prepare_std .= " --phoneme-alphabet \"$alphabet\" ";
			$prepare_std .= " --nss-alphabet \"$nssAlphabet\" ";
			$prepare_std .= " --xml " if($OPT_XML);
			$prepare_std .= " -v " if($OPT_VERBOSE);
			$prepare_std .= " -c " if($OPT_CHECK);
			$prepare_std .= " -1 ";
			$prepare_std .= " --tmp-dir=$tmpDir " ;
			$prepare_std .= " --split-utterances " if($OPT_SPLIT_UTTERANCES);
			$prepare_std .= " $inputFile " ;
			
			push (@commands, $prepare_std);
			
		}
		
		
		############################
		# Select utterance
		case "select utterance" {
			my $select_cmd = "roots-extract --index $OPT_UTTERANCE_INDEX --base-dir $inputDirectory -";
			
			push (@commands, $select_cmd);
		}
		
		
		
		############################
		# Linguistic analysis
		case "linguistics" {
			
			if ($OPT_LANGUAGE eq "fr"){
				if ($OPT_STANFORD) {
					my $pos_std  = $PERL_EXEC." ".$scriptDirectory."/20-postagger-stanford.pl ";
					$pos_std .= " --merge-all ";
					$pos_std .= " -g \"$rootsLabel_graphemeSeq\" ";
					$pos_std .= " -w \"$rootsLabel_wordPosSeq\" ";
					$pos_std .= " -p \"$rootsLabel_posSeq\" ";
					$pos_std .= " -v " if($OPT_VERBOSE);
					$pos_std .= " -k " if($KEEP_ALL);
					$pos_std .= " -c " if($OPT_CHECK);
					$pos_std .= " --tmp-dir=$tmpDir " ;
					
					push (@commands, $pos_std);
				}
				elsif ($OPT_SYNAPSE) {
					my $pos_synapse  = $PERL_EXEC." ".$scriptDirectory."/20-postagger-synapse.pl ";
					$pos_synapse .= " --merge-all ";
					$pos_synapse .= " --grapheme-label \"$rootsLabel_graphemeSeq\" ";
					$pos_synapse .= " --word-label \"$rootsLabel_wordSeq\" ";
					$pos_synapse .= " --word-lin-label \"$rootsLabel_wordPosSeq\" ";
					$pos_synapse .= " --pos-lin-label \"$rootsLabel_posSeq\" ";
					$pos_synapse .= " -v " if($OPT_VERBOSE);
					$pos_synapse .= " -k " if($KEEP_ALL);
					$pos_synapse .= " --tmp-dir=$tmpDir " ;
					
					push (@commands, $pos_synapse);
				}
				else {
					die("No linguistic analysis tool provided.\n");
				}
			}elsif ($OPT_LANGUAGE eq "en") {
				my $pos_std  = $PERL_EXEC." ".$scriptDirectory."/20-postagger-stanford-english.pl ";
				$pos_std .= " -m ";
				$pos_std .= " -g \"$rootsLabel_graphemeSeq\" ";
				$pos_std .= " -w \"$rootsLabel_wordPosSeq\" ";
				$pos_std .= " -p \"$rootsLabel_posSeq\" ";
				$pos_std .= " -v " if($OPT_VERBOSE);
				$pos_std .= " -k " if($KEEP_ALL);
				$pos_std .= " -c " if($OPT_CHECK);
				$pos_std .= " --tmp-dir=$tmpDir " ;
				
				push (@commands, $pos_std);
			}
		}
		
		
		
		
		############################
		# Pronunciation generation
		case "phonetization" {
			
			if($OPT_LANGUAGE eq "fr" && $OPT_USE_VOXYGEN) {
				my $phn_slb_voxygen =  $PERL_EXEC." ".$scriptDirectory."/30-phonetize-voxygen.pl ";
				$phn_slb_voxygen .= " -m ";
				$phn_slb_voxygen .= " -u \"$alphabet\" ";
				$phn_slb_voxygen .= " -g \"$rootsLabel_graphemeSeq\" ";
				$phn_slb_voxygen .= " -p \"$rootsLabel_phnSeq\" ";
				$phn_slb_voxygen .= " -n \"$rootsLabel_nssSeq\" ";
				$phn_slb_voxygen .= " -o \"$rootsLabel_orderSeq\" ";
				$phn_slb_voxygen .= " -b \"$rootsLabel_slbSeq\" ";
				$phn_slb_voxygen .= " -v " if($OPT_VERBOSE);
				$phn_slb_voxygen .= " -c " if($OPT_CHECK);
				$phn_slb_voxygen .= " -k " if($KEEP_ALL);
				
				push (@commands, $phn_slb_voxygen);
			}
			elsif ($OPT_LANGUAGE eq "fr" && $OPT_useLiaphon) {
				my $phn_liaphon = $PERL_EXEC." ".$scriptDirectory."/30-phonetize-liaphon.pl ";
				$phn_liaphon .= " -m ";
				$phn_liaphon .= " -w \"$rootsLabel_wordPhnSeq\" ";
				$phn_liaphon .= " --phoneme-alphabet \"$alphabet\" ";
				$phn_liaphon .= " --nss-alphabet \"$nssAlphabet\" ";
				$phn_liaphon .= " -p \"$rootsLabel_phnSeq\" ";
				$phn_liaphon .= " -o \"$rootsLabel_orderSeq\" ";
				$phn_liaphon .= " -n \"$rootsLabel_fillerSeq\" ";
				$phn_liaphon .= " -g \"$rootsLabel_graphemeSeq\" ";
				$phn_liaphon .= " -q \"$rootsLabel_usrphnSeq\" ";
				$phn_liaphon .= " -r \"$rootsLabel_orderTextSeq\" ";
				$phn_liaphon .= " -k " if($KEEP_ALL);
				$phn_liaphon .= " -v " if($OPT_VERBOSE);
				$phn_liaphon .= " --tmp-dir=$tmpDir " ;
				$phn_liaphon .= " --config=".$scriptDirectory."/phonetisation-synthese.conf " ;
				
				push (@commands, $phn_liaphon);
			}
			elsif($OPT_USE_GRUMPH) {
				my $keep_temp = "";
				if ($KEEP_ALL) { $keep_temp = "--keep-temp "; }
				my $verbose = "";
				if ($OPT_VERBOSE) { $verbose = "--verbose "; }
				my $use_pos = "";
				if (defined($grumph_config{"USE_POS"}) && $grumph_config{"USE_POS"} == 1) {
					$use_pos = "--use-pos ";	
				}
				my $dict_pos_seq = "";
				if (defined($grumph_config{"DICT_POS_SEQ"})) {
					$dict_pos_seq = "--dict-pos-sequence=\"$grumph_config{'DICT_POS_SEQ'}\" ";
					$dict_pos_seq .= " --output-pos-sequence=\"$grumph_config{'DICT_POS_SEQ'}\" ";
				}     
				my $elision = "";
				if (defined($grumph_config{"ELISION"})) {
					$elision = "--elision-crf=$grumph_config{'ELISION'} ";
				}
				my $force_case = "";
				if (defined($grumph_config{"FORCE_CASE"})) {
					$force_case = "--$grumph_config{'FORCE_CASE'} ";
				}
				my $phonetizer_alphabet = "";
				if (defined($grumph_config{"ALPHABET"})) {
					$phonetizer_alphabet = "--phoneme-alphabet=$grumph_config{'ALPHABET'} ";
				}
				my $phn_grumph = <<EOCOMMAND;
				$PERL_EXEC $scriptDirectory/30-phonetize-grumph.pl \\
	--word-sequence=\"$rootsLabel_wordPosSeq\" \\
	--pos-sequence=\"$rootsLabel_posSeq\" \\
	--grapheme-sequence=\"$rootsLabel_graphemeSeq\" \\
	--dict-word-sequence=\"$grumph_config{'DICT_WORD_SEQ'}\" \\
	$dict_pos_seq \\
	--output-word-sequence=\"$rootsLabel_wordPhnSeq\" \\
	--output-grapheme-sequence=\"$rootsLabel_graphemePhnSeq\" \\
	--output-phoneme-sequence=\"$rootsLabel_phnSeq\" \\
	--output-confidence-sequence=\"$rootsLabel_phnConfSeq\" \\
	-t $tmpDir --remove-lexicon --remove-g2p $keep_temp $verbose \\
	$use_pos \\
	$phonetizer_alphabet \\
	$force_case \\
	--nbest $OPT_GRUMPH_N_PRON \\
	--nbest-oovs $OPT_GRUMPH_N_PRON \\
	--load-index $grumph_config{'DICT_INDEX'} \\
	--g2p-crf=$grumph_config{'G2P'} \\
	$elision \\
	- \\
	$tmpDir/L.fst \\
	$grumph_config{'DICT'} \\
EOCOMMAND
				push (@commands, $phn_grumph);
				
				
				for (my $i = 0; $i < $OPT_GRUMPH_N_PRON; $i++) {
					my $filler_grumph =  $PERL_EXEC." ".$scriptDirectory."/35-add-filler-grumph.pl ";
					$filler_grumph .= " --pos-sequence \"".$grumph_config{'DICT_POS_SEQ'}."\" ";
					$filler_grumph .= " --word-sequence \"$rootsLabel_wordSeq\" ";
					$filler_grumph .= " --phoneme-sequence \"$rootsLabel_phnSeq $i\" ";
					$filler_grumph .= " --filler-sequence \"$rootsLabel_fillerSeq $i\" ";
					$filler_grumph .= " --ordering-sequence \"$rootsLabel_orderSeq $i\" ";
					$filler_grumph .= " --nss-alphabet \"$nssAlphabet\" ";
					$filler_grumph .= " -t \"$tmpDir\" ";
					$filler_grumph .= " -v " if($OPT_VERBOSE);
					push (@commands, $filler_grumph);
				}
				
				$rootsLabel_phnSeq = "$rootsLabel_phnSeq $OPT_GRUMPH_I_PRON";
				$rootsLabel_fillerSeq = "$rootsLabel_fillerSeq $OPT_GRUMPH_I_PRON";
				$rootsLabel_orderSeq = "$rootsLabel_orderSeq $OPT_GRUMPH_I_PRON";
			}elsif($OPT_USE_ESPEAK)
			{
				$rootsLabel_wordPhnSeq = $rootsLabel_wordSeq;

				my $phn_espeak = $PERL_EXEC." ".$scriptDirectory."/30-phonetize-espeak.pl ";
				$phn_espeak .= " -m ";
				$phn_espeak .= " -w \"$rootsLabel_wordPhnSeq\" ";
				$phn_espeak .= " --phoneme-alphabet \"$alphabet\" ";
				$phn_espeak .= " --nss-alphabet \"$nssAlphabet\" ";
				$phn_espeak .= " -p \"$rootsLabel_phnSeq\" ";
				$phn_espeak .= " -P \"$rootsLabel_posSeq\" ";
				$phn_espeak .= " -o \"$rootsLabel_orderSeq\" ";
				$phn_espeak .= " -n \"$rootsLabel_fillerSeq\" ";
				$phn_espeak .= " -g \"$rootsLabel_graphemeSeq\" ";
				$phn_espeak .= " -q \"$rootsLabel_usrphnSeq\" ";
				$phn_espeak .= " -r \"$rootsLabel_orderTextSeq\" ";
				$phn_espeak .= " --language \"$OPT_LANGUAGE\" ";				
				$phn_espeak .= " -k " if($KEEP_ALL);
				$phn_espeak .= " -v " if($OPT_VERBOSE);
				$phn_espeak .= " --tmp-dir=$tmpDir " ;

				if ($OPT_USE_ESPEAK_MONOPHTHONGS) {
					$phn_espeak .= " --monophthongs " ;
				}
				
				push (@commands, $phn_espeak);				
			}else{
				die("Combination Language/Phonetizer not supported.\n");
			}			
		}
		
		
		
		
		############################
		# Building of syllables
		case "syllabification" {
			if($OPT_USE_ESPEAK)
						{
							$rootsLabel_wordPhnSeq = $rootsLabel_wordSeq;
						}
			
			if ($OPT_LANGUAGE eq "fr") {
				my $slb = $PERL_EXEC." ".$scriptDirectory."/40-syllabation-french.pl ";
				$slb .= " -w \"$rootsLabel_wordPhnSeq\" ";
				$slb .= " -i \"$rootsLabel_phnSeq\" ";
				$slb .= " -s \"$rootsLabel_orderSeq\" ";
				$slb .= " -n \"$rootsLabel_slbSeq\" ";
				$slb .= " -k " if($KEEP_ALL);
				$slb .= " -v " if($OPT_VERBOSE);
				$slb .= " --tmp-dir=$tmpDir " ;
				
				if(!$OPT_USE_VOXYGEN) {
					push (@commands, $slb);
				}
			}elsif ($OPT_LANGUAGE eq "en"){
				my $slb = $PERL_EXEC." ".$scriptDirectory."/40-syllabation-english.pl ";
				$slb .= " -w \"$rootsLabel_wordPhnSeq\" ";
				$slb .= " -i \"$rootsLabel_phnSeq\" ";
				$slb .= " -s \"$rootsLabel_orderSeq\" ";
				$slb .= " -n \"$rootsLabel_slbSeq\" ";
				$slb .= " -k " if($KEEP_ALL);
				$slb .= " -v " if($OPT_VERBOSE);
				$slb .= " --tmp-dir=$tmpDir " ;
				push (@commands, $slb);
			}		 
		}
		
		
		
		
		############################
		# Corrections (notably on NSS sequence)
		case "synthesis preparation" {
			
			if(!$OPT_USE_VOXYGEN)
			{
				my $prepsyn =  $PERL_EXEC." ".$scriptDirectory."/45-prepare-synthesis.pl ";
				$prepsyn .= " --phoneme-alphabet \"$alphabet\" ";
				$prepsyn .= " --phoneme-alphabet-file \"$alphabetFile\" ";
				$prepsyn .= " --nss-alphabet=\"".$nssAlphabet."\" ";
				$prepsyn .= " -i \"$rootsLabel_phnSeq\" ";
				$prepsyn .= " -w \"$rootsLabel_wordPhnSeq\" ";
				$prepsyn .= " -o \"$rootsLabel_orderSeq\" ";
				$prepsyn .= " -y \"$rootsLabel_slbSeq\" ";
				$prepsyn .= " -e \"$rootsLabel_fillerSeq\" ";
				$prepsyn .= " -s \"$rootsLabel_nssSeq\" ";
				$prepsyn .= " -v " if($OPT_VERBOSE);
				$prepsyn .= " -c " if($OPT_CHECK);
				$prepsyn .= " -k " if($KEEP_ALL);
				$prepsyn .= " --tmp-dir=$tmpDir " ;
				
				push(@commands , $prepsyn);
			}
		}
		
				
		############################
		# Duration prediction
		case "duration" {
			$durationLogFilename = $outputDirectory."/".$outputBaseFilename."-predicted-dur.log";
			
			if($DUR_NETWORK ne "")
			{
				my $adddur =  $PERL_EXEC." ".$scriptDirectory."/47-add-durations.pl ";
				$adddur .= " $DUR_NETWORK " ;
				$adddur .= " --phoneme-sequence \"$rootsLabel_phnSeq\" ";
				$adddur .= " --word-sequence \"$rootsLabel_wordPhnSeq\" ";
				$adddur .= " --segment-sequence \"$rootsLabel_orderSeq\" ";
				$adddur .= " --syllable-sequence \"$rootsLabel_slbSeq\" ";
				$adddur .= " --filler-sequence \"$rootsLabel_fillerSeq\" ";
				$adddur .= " --nss-sequence \"$rootsLabel_nssSeq\" ";
				$adddur .= " --duration-sequence \"$rootsLabel_durSeq\" ";
				$adddur .= " -v " if($OPT_VERBOSE);
				$adddur .= " -k " if($KEEP_ALL);
				$adddur .= " --tmp-dir=$tmpDir " ;
				$adddur .= " --context-size=$contextSize " ;
				$adddur .= " --duration-log=\"$durationLogFilename\" " if ($flagCreateDurationLog);
				
				push(@commands , $adddur);
			}
		}
		
		
		##########################################
		
		#    $scriptDirectory."/50-synthesize.pl $corpusConf --output-dir $outputDirectory  --stdio --segment=Ordering --allophone=Phoneme --nss=NSS --word=Word --syllable=Syllable --pitch -s 2  --overwrite --weight-file ../common/expe/corprep/corpus_weight_configuration.txt  --weight-policy Smoothing",
		
		############################
		# Synthesis
		case "synthesis" {
			
			my $syntOutputBaseFilename = $outputBaseFilename;
			if($flagModifyProsody)
			{
				$syntOutputBaseFilename .= "-synt";
				$flagCreatePmkFile = 1;
			}
			
			my $synthesize_std = $PERL_EXEC." ".$scriptDirectory."/50-synthesize.pl ";
			$synthesize_std .= " --output-dir=\"$outputDirectory\" ";
			$synthesize_std .= " --basename=\"$syntOutputBaseFilename\" ";
			$synthesize_std .= " --stdio ";
			$synthesize_std .= " --phoneme-alphabet \"$alphabet\" ";
			$synthesize_std .= " --segment=\"$rootsLabel_orderSeq\" ";
			$synthesize_std .= " --allophone=\"$rootsLabel_phnSeq\" ";
			$synthesize_std .= " --nss=\"$rootsLabel_nssSeq\" ";
			$synthesize_std .= " --word=\"$rootsLabel_wordSeq\" ";
			$synthesize_std .= " --syllable=\"$rootsLabel_slbSeq\" ";
			$synthesize_std .= " --pos \"$rootsLabel_posSeq\" ";
			$synthesize_std .= " --duration-sequence \"$rootsLabel_durSeq\" ";
			$synthesize_std .= " --pitch " if($flagPitch);
			$synthesize_std .= " --duration " if($flagDuration);
			$synthesize_std .= " -s \"$lengthmax\" " ;
			$synthesize_std .= " --ph-dur-min $durMin " if($durMin ne "");
			$synthesize_std .= " --shared=\"$sharedName\" " if($sharedName ne "");
			$synthesize_std .= " --config=\"$corpusConf\" " if($corpusConf ne "" && $sharedName eq "");
			$synthesize_std .= " --weight-file \"$weightFile\" " if($weightFile ne "");
			$synthesize_std .= " --weight-policy \"$weightPolicy\" " if($weightPolicy ne "");
			$synthesize_std .= " --path-file \"$outputCsv\" " if($outputCsv ne "");
			$synthesize_std .= " --overwrite ";
			$synthesize_std .= " --algorithm=$algorithm ";
			$synthesize_std .= " --stop-mode=$stopMode ";
			$synthesize_std .= " --required-path=$requiredPath "; # if($stopMode eq "pathno");
			$synthesize_std .= " --min-cost=$minCost ";
			$synthesize_std .= " --no-filter " if($flagNoFilters);
			$synthesize_std .= " --heap-max=$viterbiMaxHeap ";
			$synthesize_std .= " --reversed-cost" if($flagReversedCost);
			$synthesize_std .= " --max-cost=$maxCost ";
			$synthesize_std .= " --max-path=$maxPath " if($stopMode eq "pathlist");
			$synthesize_std .= " --weight-tc=$weightTC " ;
			$synthesize_std .= " --weight-cc=$weightCC " ;
			$synthesize_std .= " --candidates-threshold=$candidates_threshold " ;
			$synthesize_std .= " --ccost-threshold=".$ccostThreshold if(defined $ccostThreshold);						
			$synthesize_std .= " --filters-target-cost " if($ftargetCost);
			$synthesize_std .= " --filters-target-cost-file=\"$targetCostFile\" " if($ftargetCost && $targetCostFile ne "");
			$synthesize_std .= " --ROOT-DIR=\"$scriptDirectory/../../..\" ";
			$synthesize_std .= " --buildpmk " if($flagCreatePmkFile);
			$synthesize_std .= " --buildlab " if($flagCreateLabFile);
			$synthesize_std .= " --sandwich " if($flagHardSandwich);
			$synthesize_std .= " --fuzzy-sandwich " if($flagFuzzySandwich);
			$synthesize_std .= " --fuzzy-sandwich-config $fuzzySandwichConfig " if(defined $fuzzySandwichConfig);			
			$synthesize_std .= " -k " if($KEEP_ALL);
			$synthesize_std .= " -v " if($OPT_VERBOSE);
			$synthesize_std .= " --debug " if($OPT_DEBUG);
			$synthesize_std .= " --tmp-dir=$tmpDir " ;
			$synthesize_std .= " --all-utterance " ;
			$synthesize_std .= " --default-duration $defaultPauseDuration " if(defined $defaultPauseDuration);
			foreach my $f (@filters)
			{
				$synthesize_std .= " --add-filter=$f ";
			}
			
			#push(@commands ,  $scriptDirectory."/50-synthesize.pl $corpusConf --output-dir $outputDirectory  --stdio --segment=Ordering --allophone=Phoneme --nss=NSS --word=Word --syllable=Syllable --pitch -s 2  --overwrite " );
			
			push(@commands, $synthesize_std);
			
		}
		
		
		
		
		
		
		############################
		# Prosody Modification
		case "prosody" {
			
			my $prosodyModifCoeffFilename = $outputDirectory."/prosody-modif-coefficients.txt";
			$labFilename = $outputDirectory."/".$syntOutputBaseFilename.".lab";
			$pmkFilename = $outputDirectory."/".$syntOutputBaseFilename.".pmk";
			
			if ($flagProsodyCorrection)
			{
				# (undef, $prosodyFile) =tempfile(DIR => ".", OPEN => 0, SUFFIX => ".txt");
				$prosodyFile = "./toto.txt";
				my $prosody_prep = $PERL_EXEC." ".$scriptDirectory."/55-prepare-modification.pl ";
				$prosody_prep .= " --prediction-file $durationLogFilename ";
				$prosody_prep .= " --lab-file $labFilename ";
				$prosody_prep .= " --pmk-file $pmkFilename ";
				$prosody_prep .= " --coeff-file $prosodyFile ";
				$prosody_prep .= " --shared=\"$sharedName\" " if($sharedName ne "");
				$prosody_prep .= " --config=\"$corpusConf\" " if($corpusConf ne "" && $sharedName eq "");
				$prosody_prep .= " --frequency $freq " if (defined $freq);
				# $prosody_prep .= " --threshold 1.5 ";
				$prosody_prep .= " --verbose " if($OPT_VERBOSE);
				$prosody_prep .= " --debug " if($OPT_DEBUG);
				
				push(@PostActions, $prosody_prep);
			}
			
			if($flagModifyProsody)
			{
				
				my $prosody_std = $PERL_EXEC." ".$scriptDirectory."/60-modify-prosody.pl ";
				$prosody_std .= " --wav-file $outputDirectory/$syntOutputBaseFilename.wav ";
				$prosody_std .= " --pmk-file $outputDirectory/$syntOutputBaseFilename.pmk ";
				$prosody_std .= " --out $outputDirectory/$outputBaseFilename.wav " ;
				$prosody_std .= " --pitch $pitchFactor " if(defined $pitchFactor);
				$prosody_std .= " --duration $durationFactor " if(defined $durationFactor);
				$prosody_std .= " --coefficient-file $prosodyFile " if(defined $prosodyFile);
				$prosody_std .= " --f0-min $f0min " if(defined $f0min);
				$prosody_std .= " --f0-max $f0max " if(defined $f0max);
				$prosody_std .= " -v " if($OPT_VERBOSE);
				
				push(@PostActions, $prosody_std);
				
			}
		}
		
		
		case "load" {
			if ($OPT_START !~ /^(?:prosody)$/) {
				push(@commands, "cat $inputFile");
			}
			if (get_step_index($OPT_START) > get_step_index("phonetization") && $OPT_USE_GRUMPH) {
				$rootsLabel_phnSeq = "$rootsLabel_phnSeq $OPT_GRUMPH_I_PRON";
				$rootsLabel_fillerSeq = "$rootsLabel_fillerSeq $OPT_GRUMPH_I_PRON";
				$rootsLabel_orderSeq = "$rootsLabel_orderSeq $OPT_GRUMPH_I_PRON";
			}
			if (get_step_index($OPT_START) > get_step_index("duration")) {
				$durationLogFilename = $outputDirectory."/".$outputBaseFilename."-predicted-dur.log";
			}
			if (get_step_index($OPT_START) > get_step_index("synthesis")) {
				$syntOutputBaseFilename = $outputBaseFilename;
			}
		}
		
		
		case "save" {
			if ($OPT_STOP !~ /^(?:synthesis|prosody)$/) {
				push(@commands, "> $outputFile");
			}
			
			
			
			else {
				die("Unknown step $current_step.\n");
			}
		}
		
		
	}
}

############################
# Run

my $cmd = join(" \\\n| ", @commands);

$cmd =~ s/\|[\s\n]+>/>/g;

#if(!$OPT_VERBOSE){$cmd.="  > /dev/null  2>&1 ";}

## TODO : remove bc it's dirty
foreach my $c (@PostActions)
{ $cmd .= "  \\\n&& ".$c; }

#if(!$OPT_VERBOSE){$cmd.="  > /dev/null  2>&1 ";}
if($OPT_VERBOSE || $OPT_COMMAND_ONLY) { print $cmd."\n"; }

if (!$OPT_COMMAND_ONLY) {
	my $error=0;
	my $pid = fork();
	if(!defined $pid)
	{
		$error = 1;
	}elsif($pid==0)
	{
		system($cmd) == 0 or $error = 1;
		exit(1) if($error == 1);
		exit(0);
	}else{
		while(wait() != -1){}         
		$error = $?;
	}
	
	#TODO: look for a better solution
	if ($flagDeleteDurationLog && !$KEEP_ALL)
	{ unlink $durationLogFilename; }
	
	if ($flagDeleteLabFile && !$KEEP_ALL)
	{ unlink $labFilename; }
	
	if ($flagDeletePmkFile && !$KEEP_ALL)
	{ unlink $pmkFilename; }
	
	if(defined $error && $error == 1){
		die "An error occured during synthesis!";
	}
}
############################

