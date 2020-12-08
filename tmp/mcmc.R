metrop1=function(n=1000,eps=0.5, radius = 0.15)
{
    vec=vector("numeric", n)
    x=0
    vec[1]=x
    for (i in 2:n) {
        innov=runif(1,-eps,eps)
        can=x+innov
        aprob=min(1,dnorm(can)/dnorm(x))
        u=runif(1)
        if (u < aprob)
            x=can
        vec[i]=x
    }
    vec
}

plot.mcmc<-function(mcmc.out)
{
    op=par(mfrow=c(2,2))
    plot(ts(mcmc.out),col=2)
    hist(mcmc.out,30,col=3)
    qqnorm(mcmc.out,col=4)
    abline(0,1,col=2)
    acf(mcmc.out,col=2,lag.max=100)
    par(op)
}

hist(metrop.out + 6)

metrop.out<-metrop1(10000,1)
plot.mcmc(metrop.out)

metrop3=function(n=1000,eps=0.5)
{
    vec = vector("numeric", n)
    x = 0
    oldll = dnorm(x, log = TRUE)
    vec[1] = x
    for (i in 2:n) {
        can = x + runif(1,-eps,eps)
        loglik=dnorm(can,log=TRUE)
        loga=loglik-oldll
        if (log(runif(1)) < loga) {
            x=can
            oldll=loglik
        }
        vec[i]=x
    }
    vec
}
