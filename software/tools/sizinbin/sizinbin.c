/* Determine size of Z80 binary file
 * and patch the size into it
 */
#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <string.h>

int main(int argc, char** argv)
    {
    unsigned char filehead[7];
    FILE *fp;
    int argidx = 1;
    int debugflg = 0;
    int exitval = 0;
    int hdridx;
    size_t file_hdr_size = 7;
    size_t file_size;
    size_t max_file_size = 65536 - 4096; /* make room for the Z80 loader */

    if (argc <= 1)
        {
        printf("Usage: %s [-d] <file to patch>\n", basename(argv[0]));
        exit(0);
        }
    if (strcmp(argv[argidx], "-d") == 0)
        {
        printf("debug flag is on\n");
        debugflg = 1;
        argidx++;
        }
    fp = fopen(argv[argidx], "r+");
    if (fp == 0)
        {
        fprintf(stderr, "%s can't open \"%s\"\n", basename(argv[0]), argv[argidx]);
        exit(1);
        }
    fseek(fp, 0, SEEK_END);
    file_size = ftell(fp);
    rewind(fp); /* to back to start again */
    if (max_file_size < file_size)
        {
        fprintf(stderr, "Size of file \"%s\" is %ld bytes which is\n",
            argv[argidx], file_size);
        fprintf(stderr, "too large to patch, max file size is %ld bytes\n",
            max_file_size);
        }
    else
        {
        if (debugflg)
            {
            printf("Size of file \"%s\" is %ld bytes\n",
                argv[argidx], file_size);
            }
        if (file_hdr_size == fread(filehead, 1, file_hdr_size, fp))
            {
            if (debugflg)
                {
                printf("  first 7 bytes of file before patch: [ ");
                for (hdridx = 0; hdridx < file_hdr_size; hdridx++)
                    printf("%02x ", filehead[hdridx]);
                printf("]\n");
                }
            if ((filehead[0] == 0xc3) && (filehead[1] == 0x07) &&
                (filehead[2] == 0x00))
                {
                rewind(fp); /* to back to start again */
                /* patch file size into byte 3 & 4 */
                filehead[3] = file_size & 0xff;
                filehead[4] = (file_size / 256) & 0xff;
                if (file_hdr_size == fwrite(filehead, 1, file_hdr_size, fp))
                    {
                    if (debugflg)
                        {
                        printf("  first 7 bytes of file after patch:  [ ");
                        for (hdridx = 0; hdridx < file_hdr_size; hdridx++)
                            printf("%02x ", filehead[hdridx]);
                        printf("]\n");
                        }
                    }
                else
                    {
                    fprintf(stderr, "%s can't write \"%s\"\n",
                        basename(argv[0]), argv[argidx]);
                    exitval = 1;
                    }
                }
            else
                {
                fprintf(stderr, "\"%s\" has invalid file header\n",
                    argv[argidx]);
                exitval = 1;
                }
            }
        else
            {
            fprintf(stderr, "%s can't read \"%s\"\n", basename(argv[0]), argv[argidx]);
            exitval = 1;
            }
        }

    fclose(fp);
    exit(exitval);
    }
