/* stripmhdr.c - Tool to strip header from Whitesmiths/COSMIC
 * multi section object file. 
 *
 * Used to create binary file linked with lnk80
 * as the +h (for multi segment) and -h for supressing
 * header output can not be used simultaneously.
 *
 * You are free to use, modify, and redistribute
 * this source code. No warranties are given.
 * Hastily Cobbled Together 2022 by Hans-Ake Lund
 *
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <error.h>
#include <libgen.h>

/* options */
char *program_name;
char *out_file_name = NULL;

void usage (int status)
    {
    if (status != EXIT_SUCCESS)
        fprintf(stderr, "Try `%s --help' for more information.\n" ,program_name);
   else
        {
        printf("Usage: %s [OPTION] [FILE]\n", program_name);
        fputs("\
Strip header from Whitesmiths/COSMIC multi section object file,\n\
  read from object FILE, or standard input\n\
  write to OFILE or standard output.\n\
  -h, --help            show help\n\
  -o, --outfile [OFILE] file name for output, default stdout\n", stdout);
        fputs ("\
With no FILE, or when FILE is -, read standard input.\n", stdout);
        }
    exit(status);
    }

/* Strip header from Whitesmiths/COSMIC multi section object file
 */
int main(int argc, char **argv)
    {
    FILE *infd = stdin;
    FILE *outfd = stdout;
    int optchr;
    int inbyte;
    int hdrlen;

    static struct option long_options[] =
        {
            {"help",    no_argument,       NULL, 'h'},
            {"outfile", required_argument, NULL, 'o'},
            {NULL, 0, NULL, 0}
        };
        /* getopt_long stores the option index here. */
    int option_index = 0;

    program_name = basename(argv[0]);
    while ((optchr = getopt_long(argc, argv, "ho:", long_options, NULL)) != -1)
        {
        switch (optchr)
            {
        case 'h':
            usage(EXIT_SUCCESS);
        case 'o':
            out_file_name = optarg;
            break;
        default:
            usage(EXIT_FAILURE);
            }
        }

    if ((optind < argc) && (argv[optind][0] != '-'))
        {
        if ((infd = fopen(argv[optind], "r")) == NULL)
            exit(EXIT_FAILURE);
        }
    else
        {
        infd = stdin;
        }
    if (fgetc(infd) != 0xc2)
        {
        fprintf(stderr, "Not a multi segment object file");
        if (infd != stdin)
            {
            fclose(infd);
            fprintf(stderr, ": %s", argv[optind]);
            }
        fprintf(stderr, "\n");
        exit(EXIT_FAILURE);
        }
    if (out_file_name)
        {
        if ((outfd = fopen(out_file_name, "w")) == NULL)
            exit(EXIT_FAILURE);
        }
    fgetc(infd); /* skip configuration byte */
    hdrlen = fgetc(infd); /* get size of header */
    hdrlen += fgetc(infd) * 256;

    while (4 < hdrlen--)
        {
        fgetc(infd);
        if (feof(infd))
            {
            fprintf(stderr, "Could not skip header\n");
            if (infd != stdin)
                fclose(infd);
            if (outfd != stdout)
                fclose(outfd);
            exit(EXIT_FAILURE);
            }
        }
    while (1)
        {
        inbyte = fgetc(infd);
        if (feof(infd))
            {
            break;
            }
        else
            {
            fputc(inbyte, outfd);
            }
        }
    if (infd != stdin)
        fclose(infd);
    if (outfd != stdout)
        fclose(outfd);
    exit(EXIT_SUCCESS);
    }
