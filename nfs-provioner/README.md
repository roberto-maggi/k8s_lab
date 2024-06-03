Deploy completo per un NFS provisione valido per ambiente di produzione

nel manifesto default-storage-class.yaml ho inserito l'annotazione

annotations:
  storageclass.kubernetes.io/is-default-class: "true"

così da rendere il SC un default per l'intero cluster,
nel caso in cui fosse meglio crearne più di uno, commentare l'annotazione e 
cambiare il nome del SC li e nei claim

