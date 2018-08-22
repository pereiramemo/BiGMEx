#!/bin/bash -l

# set -x

set -o pipefail

###############################################################################
# 1. load general configuration
###############################################################################

source /bioinfo/software/conf
# source /home/memo/Google_Drive/Doctorado/workspace/ufBGCtoolbox/\
# bgc_dom_merged_shannon/resources/conf_local

###############################################################################
# 2. parse parameters 
###############################################################################

while :; do
  case "${1}" in
#############
  -a|--abund_table)
  if [[ -n "${2}" ]]; then
   ABUND_TABLE="${2}"
   shift
  fi
  ;;
  --abund_table=?*)
  ABUND_TABLE="${1#*=}" # Delete everything up to "=" and assign the remainder.
  ;;
  --abund_table=) # Handle the empty case
  printf "ERROR: --abund_table requires a non-empty option argument.\n"  >&2
  exit 1
  ;;
#############
  -fs|--font_size)
   if [[ -n "${2}" ]]; then
     FONT_SIZE="${2}"
     shift
   fi
  ;;
  --font_size=?*)
  FONT_SIZE="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --font_size=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  -o|--outdir)
   if [[ -n "${2}" ]]; then
     OUTDIR_EXPORT="${2}"
     shift
   fi
  ;;
  --outdir=?*)
  OUTDIR_EXPORT="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --outdir=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  -pc|--plot_rare_curve)
   if [[ -n "${2}" ]]; then
     PLOT_RARE_CURVE="${2}"
     shift
   fi
  ;;
  --plot_rare_curve=?*)
  PLOT_RARE_CURVE="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --plot_rare_curve=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  -pr|--prefix)
   if [[ -n "${2}" ]]; then
     PREFIX="${2}"
     shift
   fi
  ;;
  --prefix=?*)
  PREFIX="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --prefix=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;   
#############
  -pw|--plot_width)
   if [[ -n "${2}" ]]; then
     PLOT_WIDTH="${2}"
     shift
   fi
  ;;
  --plot_width=?*)
  PLOT_WIDTH="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --plot_width=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;  
#############
  -ph|--plot_height)
   if [[ -n "${2}" ]]; then
     PLOT_HEIGHT="${2}"
     shift
   fi
  ;;
  --plot_height=?*)
  PLOT_HEIGHT="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --plot_height=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
#############
  -n|--num_iter)
   if [[ -n "${2}" ]]; then
     NUM_ITER="${2}"
     shift
   fi
  ;;
  --num_iter=?*)
  NUM_ITER="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --num_iter=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;
 #############
  -s|--sample_increment)
   if [[ -n "${2}" ]]; then
     SAMPLE_INCREMENT="${2}"
     shift
   fi
  ;;
  --sample_increment=?*)
  SAMPLE_INCREMENT="${1#*=}" # Delete everything up to "=" and assign the 
# remainder.
  ;;
  --sample_increment=) # Handle the empty case
  printf 'Using default environment.\n' >&2
  ;;   
#############
    --)              # End of all options.
    shift
    break
    ;;
    -?*)
    printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
    ;;
    *) # Default case: If no more options then break out of the loop.
    break
    esac
    shift
done

###############################################################################
# 3. define output
###############################################################################

THIS_JOB_TMP_DIR="${OUTDIR_EXPORT}"
THIS_OUTPUT_TMP_RARE_TSV="${THIS_JOB_TMP_DIR}/${PREFIX}_rare_div_est.tsv"
THIS_OUTPUT_TMP_SUMM_TSV="${THIS_JOB_TMP_DIR}/${PREFIX}_summary_rare_div_est.tsv"
THIS_OUTPUT_TMP_IMAGE="${THIS_JOB_TMP_DIR}/${PREFIX}_rare_div_est.pdf"

###############################################################################
# 4. diversiy estimates
###############################################################################

"${r_interpreter}" --vanilla --slave <<RSCRIPT

  options(warn=-1)
  library(vegan, quietly = TRUE, warn.conflicts = FALSE)
  library(dplyr, quietly = TRUE, warn.conflicts = FALSE)
  library(tidyr, quietly = TRUE, warn.conflicts = FALSE)
  library(tibble, quietly = TRUE, warn.conflicts = FALSE)
  library(ggplot2, quietly = TRUE, warn.conflicts = FALSE)
  options(warn=0)

  ### load data
  CLUSTER <- read.table(file = "${ABUND_TABLE}",
			sep = "\t", header = F)
  colnames(CLUSTER) <- c("clust_id","sample_id","seq_id","abund")
  ### 

  ### format table
  ODU_TABLE <- CLUSTER %>% 
               group_by(clust_id, sample_id) %>%
               summarize(clust_abund = sum(abund)) %>%
               spread(key = clust_id, value = clust_abund) %>% 
	       remove_rownames(.) %>% 
               as.data.frame(.) %>%
               tibble::remove_rownames(.) %>%
               tibble::column_to_rownames("sample_id") %>%
               round(., digits = 0)
             
  ODU_TABLE[is.na(ODU_TABLE)] <- 0
  ###

  ### rarefy and compute diversity 
  s <- "${SAMPLE_INCREMENT}" %>% as.numeric()
  N <- "${NUM_ITER}" %>% as.numeric()
  w <- "${PLOT_WIDTH}" %>% as.numeric()
  h <- "${PLOT_HEIGHT}" %>% as.numeric()
  f1 <- "${FONT_SIZE}" %>% as.numeric()
  f2 <- f1 +2 
  
  source("${SOFTWARE_DIR}/rare_div.R")

  if ( s > min(rowSums(ODU_TABLE)) ) {
       s <- min(rowSums(ODU_TABLE))
       text <- paste("increment size reset to", s, sep = " " )
       print(text)
  }


  ODU_TABLE_div_est <- rare_div(x = ODU_TABLE,
                                n_iter = N, 
                                by = s)
                                                            
  ODU_TABLE_div_est_summary <- ODU_TABLE_div_est %>%
                               group_by(sample_id, size) %>%
                               arrange(size) %>% 
                               summarize(mean = mean(diversity), sd = sd(diversity)) %>% 
                               ungroup()
                              
  ### format diversity table for rarefying plot
  if ( "${PLOT_RARE_CURVE}" %in% c("t","T")) {
  
    p <- ggplot(ODU_TABLE_div_est_summary, aes(x = size, y = mean, color = sample_id)) +
                geom_line( size = 1, alpha = 0.9) +
                geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), alpha = 0.6) +
                xlab("Sample size") +
                ylab("Shannon index") +
                theme_light() +
                scale_color_hue(c=70, l=40,h.start = 200,direction = -1, name = "Sample") +
                theme(axis.text.y = element_text(size = f1, color = "black"), 
                      axis.text.x = element_text(size = f1, color = "black",
                                                 angle = 45, hjust = 1),
                      axis.title.x = element_text(size = f2, color = "black"),
                      axis.title.y = element_text(size = f2, color = "black",
                                                  margin = unit(c(0, 5, 0, 0),"mm"))) 


    pdf(file = "${THIS_OUTPUT_TMP_IMAGE}", width = w, height = h)
    print(p)		          
    dev.off()
  }  

  ### write output tables
  ODU_TABLE_div_est_rare <- ODU_TABLE_div_est %>% 
                            select(-subsample_id) %>%
                            as.data.frame() 
      
  write.table(file = "${THIS_OUTPUT_TMP_RARE_TSV}",
              x = ODU_TABLE_div_est,
              sep = "\t", quote = F, 
              row.names = F, col.names = T)

  write.table(file = "${THIS_OUTPUT_TMP_SUMM_TSV}",
              x = ODU_TABLE_div_est_summary,
              sep = "\t",
              quote = F, 
              row.names = F, 
              col.names = T)
  ####

RSCRIPT