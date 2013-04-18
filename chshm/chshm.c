/***********************************************************************
 * chshm: A tool to change shared memory ownership and permission
 *
 * Author:  Curu Wong 
 * Date:    2013-04-18
 **********************************************************************
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.

 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>
#include <getopt.h>

void print_usage(char *prog_name){
		fprintf(stderr, "Usage: %s [Options] shmid ...\n", prog_name);
		fprintf(stderr, "Options:\n");
		fprintf(stderr, "    -u|--user <user name>	change owner to <user name>\n");
		fprintf(stderr, "    -g|--group <group name> 	change group to <grou pname>\n");
		fprintf(stderr, "    -m|--mode <mode>		change mode to <mode> in octal\n");
		fprintf(stderr, "\neg:\n");
		fprintf(stderr, "    %s -u nobody -m 0660 65535 \n", prog_name);
		fprintf(stderr, "    This will change shm id 65535's owner to nobody, mode to 0660\n");
}

int chshm(int shmid, uid_t uid, gid_t gid, int mode)
{
	int ret;
	struct shmid_ds buf;

	//save current stat
	ret = shmctl(shmid, IPC_STAT, &buf);
	if(ret == -1 ){
		perror("error get shared memory info");
		return -1;
	}	

	// if uid or gid is -1, it will not be changed
	if( uid != -1 ){
		buf.shm_perm.uid = uid;
	}
	if( gid != -1 ){
		buf.shm_perm.gid = gid;
	}
	
	if(mode != -1){
		buf.shm_perm.mode = mode;
	}
	
	ret = shmctl(shmid, IPC_SET, &buf);
	if( ret == -1){
		perror("error: unable to change owner");
		return -1;
	}
	return 0;
}

int main(int argc, char *argv[])
{
	uid_t uid = -1;
	gid_t gid = -1;
	mode_t mode = -1;
	int shmid;
	struct group *grent;
	struct passwd *pwent;	

	int c;
	static int help_flag = 0;
	while (1){
		static struct option long_options[] = {
				{"help", no_argument, &help_flag, 1},
				{"user", required_argument, 0, 'u'},
				{"group", required_argument, 0, 'g'},
				{"mode", required_argument, 0, 'm'},
				{0,   0,   0,  0  }
		};
		int option_index = 0;
		c = getopt_long (argc, argv, "hu:g:m:",
                            long_options, &option_index);
		if (c == -1){
			break;
		}
		switch(c) {
			case 'u':
				errno = 0;
				pwent = getpwnam(optarg);
				if(pwent != NULL){
					uid= pwent->pw_uid;
				}else{
					if(errno){	
						perror("getpwnam");
					}else{
						fprintf(stderr, "no such user '%s'\n", optarg);
					}	
					exit(EXIT_FAILURE);
				}
				break;
			case 'g':
				errno = 0;
				grent = getgrnam(optarg);
				if(grent != NULL){
					gid= grent->gr_gid;
				}else{
					if(errno){	
						perror("getgrnam");
					}else{
						fprintf(stderr, "no such group '%s'\n", optarg);
					}	
					exit(EXIT_FAILURE);
				}
				break;
			case 'm':
				mode = strtoul(optarg, NULL, 8);
				break;
			case 'h':
				help_flag = 1;
				break;	
			default:
				print_usage(argv[0]);
				exit(EXIT_FAILURE);
		
		}

	}

	if(optind >= argc || help_flag ){
		print_usage(argv[0]);
		exit(0);
	}
	while(optind < argc){
		shmid = strtoul(argv[optind], NULL, 10);
		if (chshm(shmid, uid, gid, mode) == -1 ){
			exit(EXIT_FAILURE);
		}
		optind++;
	}
	return 0;
}
