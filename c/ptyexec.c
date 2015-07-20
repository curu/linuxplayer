/***************************************************************
 * ptyexec: exec cmd in pty
 * prevent process from being killed by SIGHUP when pty closed
 * 
 * author: Curu Wong
 * date:   2015-07-18
 * License: GPL v3
 **************************************************************
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pty.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/epoll.h>
#include <signal.h>

#ifndef epoll_pwait
int epoll_pwait(int epfd, struct epoll_event *events,
               int maxevents, int timeout,
               const sigset_t *sigmask){
	int ready;
	sigset_t origmask;
	sigprocmask(SIG_SETMASK, sigmask, &origmask);
	ready = epoll_wait(epfd, events, maxevents, timeout);
	sigprocmask(SIG_SETMASK, &origmask, NULL);
	return ready;
}
#endif

static int exit_status = -1;

void child_handler(int signum)
{
	int status;
	wait(&status);
	if (WIFEXITED(status)){
		exit_status = WEXITSTATUS(status);
	}else{
		//maybe killed
		exit_status = 1;
	}
}

int pty_exec(int use_shell, char * const* argv){
	int timeout = 50;
	char buf[BUFSIZ];
	pid_t pid;
	int master_fd, slave_fd, epfd, nfds;
	int ret,flags, status;
	struct epoll_event ev, events[1];
	ssize_t nread;

	sigset_t mask;
	sigemptyset(&mask);
	sigaddset(&mask, SIGCHLD);

	ret = openpty(&master_fd, &slave_fd, NULL, NULL, NULL);	
	if ( ret == -1){
		perror("openpty");
		return 1;
	}

	//fork to exec cmd and monitor output
	pid = fork();
	if ( pid > 0 ){
		//***parent: read and print child output***
		close(slave_fd);
		//handle child exit
		signal(SIGCHLD, child_handler);

		//set pty fd to non blocking mode
		flags = fcntl(master_fd, F_GETFL, 0);
		fcntl(master_fd, F_SETFL, flags | O_NONBLOCK);

		//read cmd output with epoll
		epfd = epoll_create(1);
		if(epfd == -1 ){
			perror("epoll_create");
			return(1);
		}
		ev.events = EPOLLIN | EPOLLHUP;
		ev.data.fd = master_fd;
		epoll_ctl(epfd, EPOLL_CTL_ADD, master_fd, &ev);

		while(1){
			if(exit_status != -1){
				break; //child exited
			}
			nfds = epoll_pwait(epfd, events, 1, timeout, &mask);
			if(nfds < 0){
				if (errno == EINTR){
					continue; //interrupted by signal etc...
				}
				perror("epoll_wait");
				exit(1);
			}
			if (nfds == 0 ){
				continue; //time out , nothing to read
			}
			if(events[0].events & EPOLLIN){
				nread = read(events[0].data.fd, buf, BUFSIZ);
				if (nread == -1){
					perror("read");
					break;
				}
				write(1, buf, nread);
			}
			if(events[0].events & EPOLLHUP){
				//pty slave closed 
				break;
			}
		}
		if(exit_status == -1){
			//SIGCHLD maybe lost, collect status.
			if (wait(&status) != -1 )
				exit_status = WEXITSTATUS(status);
		}
		return exit_status;
	}else{
		/*child: redirect stdin, stdout, and stderr to slave_fd
		 * I am child of old session, impossible to be session leader.
		 * so when pty is closed, no HUP will be sent to me
		*/
		close(master_fd);
		dup2(slave_fd, 0);
		dup2(slave_fd, 1);
		dup2(slave_fd, 2);
		if(use_shell){
			ret = execlp("sh", "sh", "-c", argv[0], NULL);

		}else{
			ret = execvp(argv[0], argv);
		}
		if (ret == -1 ){
			perror("exec");
			exit(1);
		}
	}
	return 0;
}

void print_usage(const char *prog)
{
	fprintf(stderr, "Usage:\n\t%s cmd args...\n", prog);
	fprintf(stderr, "\t%s -c 'shell cmd string'\n", prog);
}

int main(int argc, char **argv){
	int use_shell = 0;
	char * const* cmd;

	//argument parsing
	if (argc < 2){
		print_usage(argv[0]);
		return 1;
	}
	if (*(argv[1]) == '-'){
		switch( *(argv[1] + 1) ){
			case 'h':
				print_usage(argv[0]);
				return 0;
			case 'c':
				use_shell = 1;
				if(argc < 3){
					print_usage(argv[0]);
					return 1;
				}
				break;
			default:
				fprintf(stderr, "ERROR: invalid option '%s'\n", argv[1]);
				print_usage(argv[0]);
				return 1;
		}

	}

	cmd = argv + 1;
	if(use_shell){
		cmd += 1;
	}
	return pty_exec(use_shell, cmd);
}

