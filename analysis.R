list.of.packages <- c("data.table","XML")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

setwd("~/git/savi-cronos-analysis")

# git log --pretty=format:%H,%ct,%s > ../savi-cronos-analysis/gitlog.csv
gitlog = fread("gitlog.csv",header=F,col.names=c("commit","date","message"))
gitlog$date = as.Date(gitlog$date/(60*60*24),origin="1970-01-01")

setwd("~/git/savi-cronos")

data.list = list()

for(i in 1:nrow(gitlog)){
  date = gitlog$date[i]
  commit = gitlog$commit[i]
  command = paste("git checkout",commit)
  system(command)
  message(date)
  all_ids = c()
  all_refs = c()
  xml_files = list.files(pattern="*.xml")
  for(xml_file in xml_files){
    file_parse = xmlParse(xml_file)
    rootnode = xmlRoot(file_parse)
    activities = getNodeSet(rootnode,"//iati-activity/iati-identifier")
    activity_ids = sapply(activities,xmlValue)
    all_ids = c(all_ids,activity_ids)
    publishers = getNodeSet(rootnode,"//iati-activity/reporting-org")
    publisher_refs = sapply(publishers,xmlGetAttr,"ref")
    all_refs = c(all_refs,publisher_refs)
  }
  tmp.df = data.frame(
    date,
    activities=length(unique(all_ids)),
    publishers=length(unique(all_refs))
  )
  data.list[[i]] = tmp.df
}

results = rbindlist(data.list)
setwd("~/git/savi-cronos-analysis")
fwrite(results,"results.csv")