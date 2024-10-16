#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <time.h>
#include <sys/time.h>
#include <math.h>
#include <stdint.h>

int main(int argc, char **argv)
{
	int pkt_size = 1024;
	uint32_t pkt_count, time_cost;
	int sockfd, ret;
	struct sockaddr_in servaddr;
	struct timeval t_begin, t_end;


	char *pkt;

	if (argc < 5)
	{
		printf("Usage:  %s <IP> <port> <packet size bytes> <package count>\n", argv[0]);
		exit(1);
	}

	sockfd=socket(AF_INET,SOCK_DGRAM,0);
	bzero(&servaddr,sizeof(servaddr));
	servaddr.sin_family = AF_INET;
	servaddr.sin_addr.s_addr=inet_addr(argv[1]);
	servaddr.sin_port=htons(strtoul(argv[2], 0,0));

	pkt_size = strtoul(argv[3], 0, 0); 
	pkt_size = pkt_size ? pkt_size : 1;
	pkt = malloc(pkt_size);
	
	pkt_count = strtoul(argv[4], 0, 0);

	printf("Sending %u package of size %d to %s:%s\n",
		   pkt_count, pkt_size, argv[1], argv[2]);

	gettimeofday(&t_begin, NULL);
	int i = 0;
	while (i < pkt_count)
	{
		ret = sendto(sockfd,pkt,pkt_size,0, (struct sockaddr *)&servaddr,sizeof(servaddr));
		if (ret < 0){
		      perror("Error: sendto");
		      break;
		}
		i++;

	}
	free(pkt);
	gettimeofday(&t_end, NULL);

	time_cost = (t_end.tv_sec*1000000 + t_end.tv_usec) - (t_begin.tv_sec*1000000 + t_begin.tv_usec);
	printf("Sent %u packet in %d.%d seconds\n", i,
		   time_cost/1000000,
		   time_cost%1000000);
}
