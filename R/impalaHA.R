### Functions are built to ensure random node connexion to impala ###
#Load of odbc and httr package
library(odbc)
library(httr)

#Test for working node in the list provided, return a named vector (true/false)
check_datanodes <- function(host, port, schema, user, password, timeout){
  tryCatch(
    expr = {
      before <- getTaskCallbackNames()
      con <-DBI::dbConnect(odbc::odbc(),
                           Driver   = ifelse(.Platform$OS.type == "windows",
                                             "Cloudera ODBC Driver for Impala",
                                             "Cloudera ODBC Driver for Impala 64-bit"),
                           Host     = host,
                           Port     = port,
                           Schema   = schema,
                           AuthMech = 3,
                           UseSASL  = 1,
                           UID      = user,
                           PWD      = password,
                           timeout   = timeout
      )
      after <- getTaskCallbackNames()
      #avoid warnings due to the connections tab from Rstudio
      # before + after + removeTaskCallback can be deleted if used out of Rstudio
      removeTaskCallback(which(!after %in% before))
      return(TRUE)
    },
    error = function(e){
      return(FALSE)
    })
}


# Allow to set a up a random node connexion
random_node_connect <- function(nodelist, port, schema,user, password, timeout = 0.5){
  if(missing(nodelist)){
    stop("nodelist is mandatory, please provide it.", call. = FALSE)
  }
  if(missing(user) | missing(password)){
    stop("user or passsword is missing, please provide it.", call. = FALSE)
  }

  #Get a vector TRUE/FALSE for responding nodes
  answered <- sapply(nodelist, check_datanodes, port = port, schema= schema, user = user, password = password,  timeout = timeout)

  #Get the names of the reponding nodes
  nodes_names <- names(answered[answered == TRUE])

  #Choose a random one :
  rand_node <- nodes_names[sample(1:length(nodes_names), 1)]

  #Message with dn choosen
  message(paste0("Connection to : ", rand_node))

  #return connexion object randomly choosen in the list of available working nodes
  return(DBI::dbConnect(odbc::odbc(),
                        Driver   = ifelse(.Platform$OS.type == "windows",
                                          "Cloudera ODBC Driver for Impala",
                                          "Cloudera ODBC Driver for Impala 64-bit"),
                        Host     = rand_node,
                        Port     = port,
                        Schema   = schema,
                        AuthMech = 3,
                        UseSASL  = 1,
                        UID      = user,
                        PWD      = password,
                        timeout   = timeout
  )
  )
}
