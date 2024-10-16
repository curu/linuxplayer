#include <stdio.h>
#include <stdlib.h>
#include <netlink/netlink.h>
#include <netlink/cache.h>
#include <netlink/route/link.h>
#include <netlink/route/tc.h>
#include <netlink/route/qdisc.h>
 
void err_exit(char *msg){
        fprintf(stderr, msg);
        exit(1);
}
int main(void){
        char *iface = "eth1";
        struct nl_sock *sock;
        struct nl_cache *link_cache, *qdisc_cache;
        struct rtnl_link *eth1;
        struct rtnl_qdisc *qdisc;
        int ifindex, txqueuelen, drops, requeues;
        int ret;
 
        //create and connect netlink socket
        sock = nl_socket_alloc();
        ret = nl_connect(sock, NETLINK_ROUTE);
        if(ret < 0 )
                err_exit("error connect to netlink_route\n");
 
        //find link
        if (rtnl_link_alloc_cache(sock, AF_UNSPEC, &link_cache) < 0)
                err_exit("error alloc link cache\n");
        ifindex = rtnl_link_name2i(link_cache, iface);
        if(!ifindex)
                err_exit("error get interface index\n");
        eth1 = rtnl_link_get(link_cache, ifindex);
        txqueuelen = rtnl_link_get_txqlen(eth1);
        rtnl_link_put(eth1);
 
        //get root qdisc
        if (rtnl_qdisc_alloc_cache(sock, &qdisc_cache) < 0)
                err_exit("error alloc qdisc cache\n");
        qdisc = rtnl_qdisc_get(qdisc_cache, ifindex, TC_HANDLE(0,0));
        if (!qdisc)
                err_exit("no qdisc found for eth1\n");
        //get qdisc stats
        drops = rtnl_tc_get_stat(TC_CAST(qdisc), RTNL_TC_DROPS);
        requeues = rtnl_tc_get_stat(TC_CAST(qdisc), RTNL_TC_DROPS);
        rtnl_qdisc_put(qdisc);
 
        printf("%s txqueuelen:%d drops:%d requeues:%d\n",
                        iface, txqueuelen, drops, requeues);
        nl_socket_free(sock);
 
        return 0;
}
               
