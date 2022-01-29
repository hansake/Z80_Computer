/* bintoc.c - Tool to translate binary file to C byte array. 
 *
 * Used to embed binary code/data blobs into a C program.
 *
 * Also made to understand how to use Getopt Long Option.
 * https://www.gnu.org/software/libc/manual/html_node/Getopt-Long-Options.html
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
#include <time.h>

/* options */
int verbose_flag = 0;
char *program_name;
char *out_file_name = NULL;
char *byte_array_name = "blob";
char *byte_array_size_name = NULL;
char *byte_array_size_name_buf = NULL;

void usage (int status)
    {
    if (status != EXIT_SUCCESS)
        fprintf(stderr, "Try `%s --help' for more information.\n" ,program_name);
   else
        {
        printf("Usage: %s [OPTION]... [FILE]...\n", program_name);
        fputs("\
Transform binary FILE(s), or standard input, to a C byte array\n\
written to OFILE or standard output.\n\
\n\
  -h, --help            show help\n\
  -o, --outfile [OFILE] file name for C code, default stdout\n\
  -n, --name [NAME]     name of the C byte array, default \"blob\"\n\
  -s, --size [NAME]     name of the unsigned int variable containing\n\
                        the size of the C byte array, default \"blob_size\"\
  -v, --verbose         output details in file\n", stdout);
        fputs ("\
With no FILE, or when FILE is -, read standard input.\n", stdout);
        }
    exit(status);
    }

/* Convert binary file into a C byte array
 */
int main(int argc, char **argv)
    {
    FILE *infd = stdin;
    FILE *outfd = stdout;
    int optchr;
    int inbyte;
    int bytecntr = 0;
    int linecntr = 0;
    int files_index;
    time_t timeval;

    static struct option long_options[] =
        {
            {"help",    no_argument,       NULL, 'h'},
            {"outfile", required_argument, NULL, 'o'},
            {"name",    required_argument, NULL, 'n'},
            {"size",    required_argument, NULL, 's'},
            {"verbose", no_argument,       NULL, 'v'},
            {NULL, 0, NULL, 0}
        };
        /* getopt_long stores the option index here. */
    int option_index = 0;

    program_name = basename(argv[0]);
    while ((optchr = getopt_long(argc, argv, "ho:n:s:v", long_options, NULL)) != -1)
        {
        switch (optchr)
            {
        case 'h':
            usage(EXIT_SUCCESS);
        case 'o':
            out_file_name = optarg;
            break;
        case 'n':
            byte_array_name = optarg;
            break;
        case 's':
            byte_array_size_name = optarg;
            break;
        case 'v':
            verbose_flag = 1;
            break;
        default:
            usage(EXIT_FAILURE);
            }
        }

    if (byte_array_size_name == NULL)
        {
        byte_array_size_name_buf = malloc(strlen(byte_array_name) + 6);
        sprintf(byte_array_size_name_buf, "%s_size", byte_array_name);
        byte_array_size_name = byte_array_size_name_buf;
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
    if (out_file_name)
        {
        if ((outfd = fopen(out_file_name, "w")) == NULL)
            exit(EXIT_FAILURE);
        }

    if (verbose_flag)
        {
        fprintf(outfd, "/* Created by the bintoc program: ");
        timeval = time(NULL);
        fprintf(outfd, "%s", asctime(localtime(&timeval)));
        files_index = optind;
        if (files_index < argc)
            {
            fprintf(outfd, " * Input file names:");
            while (files_index < argc)
                fprintf(outfd, " %s,", argv[files_index++]);
            fprintf(outfd, "\b \n");
            }
        if (out_file_name)
            fprintf(outfd, " * Output file name: %s\n", out_file_name);
        fprintf(outfd, " * Byte array name: %s\n", byte_array_name);
        fprintf(outfd, " * Variable with size of byte array: %s\n",
            byte_array_size_name);
        fprintf(outfd, " */\n");
        }


    fprintf(outfd, "const unsigned char %s[] = {\n    ", byte_array_name);
    while (1)
        {
        inbyte = fgetc(infd);
        if (feof(infd))
            {
            if (infd == stdin)
                break;
            fclose(infd);
            if (++optind < argc)
                {
                if ((infd = fopen(argv[optind], "r")) == NULL)
                    exit(EXIT_FAILURE);
                }
            else
                break;
            }
        else
            {
            fprintf(outfd, "0x%02x, ", inbyte);
            bytecntr++;
            linecntr++;
            if (12 <= linecntr)
                {
                fprintf(outfd, "\n    ");
                linecntr = 0;
                }
            }
        }
    fprintf(outfd, "};\n");
    fprintf(outfd, "const int %s = %d;\n", byte_array_size_name, bytecntr);
    if (byte_array_size_name_buf)
        free(byte_array_size_name_buf);
    if (outfd != stdout)
        fclose(outfd);
    exit(EXIT_SUCCESS);
    }
