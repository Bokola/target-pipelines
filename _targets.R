browseURL("https://raps-with-r.dev/targets.html")
library(targets)
# run in parallel
# for independent pipelines

library(targets)
library(future)
library(future.callr)
plan(callr)
library(tarchetypes) # render .Rmd

# This is an example _targets.R file. Every
# {targets} pipeline needs one.
# Use tar_script() to create _targets.R and tar_edit()
# to open it again for editing.
# Then, run tar_make() to run the pipeline
# and tar_read(data_summary) to view the results.

# Define custom functions and other global objects.
# This is where you write source(\"R/functions.R\")
# if you keep your functions in external scripts.
summarize_data <- function(dataset) {
  colMeans(dataset)
}

# save plot to disk
save_plot <- function(filename, ...){
  png(filename)
  plot(...)
  dev.off()
  filename
}

# Sometimes you gotta take your time
slow_summary <- function(...) {
  Sys.sleep(30)
  summary(...)
}

#  return path to the file
path_data <- function(path){
  path
}


# Set target-specific options such as packages:
tar_option_set(packages = c("dplyr", "flextable", "ggplot2", "skimr"))

# End this file with a list of target objects.
list(
  tar_target(data, data.frame(x = sample.int(100), y = sample.int(100))),
  tar_target(data_summary, summarize_data(data)) # Call your custom functions.,
  ,tar_target(
    data_plot,
    save_plot(filename = "plot.png", data),
    format = "file"
  )
)

# load all to environment
# tar_load_everything()

# handling files

# this does not track changes to data
data(mtcars)
write.csv(mtcars,
          "mtcars.csv",
          row.names = FALSE)
list(
  tar_target(
    data_mtcars,
    read.csv("mtcars.csv")
  )
  ,tar_target(
    summary_mtcars,
    summary(data_mtcars)
  )
  ,tar_target(
    plot_mtcars,
    save_plot(filename = "mtcars_plot.png", data_mtcars),
    format = "file"
  )
)
# update data
write.csv(head(mtcars), "mtcars.csv", row.names = F)
# running the pipeline again ignores changes to the data
# data back
write.csv(mtcars,
          "mtcars.csv",
          row.names = FALSE)
# targets need to be pure functions that return something
# to be able to track changes
# modify first target to return the path to the file

list(
  tar_target(
    path_data_mtcars,
    path_data("mtcars.csv"), format = "file"
  )
  ,tar_target(
    data_mtcars,
    read.csv(path_data_mtcars)
  )
  ,tar_target(
    summary_mtcars,
    summary(data_mtcars)
  )
  ,tar_target(
    plot_mtcars,
    save_plot(filename = "mtcars_plot.png",
              data_mtcars), format = "file"
  )
)


# pipeline to run in parallel with tar_make_future()
list(
  tar_target(
    path_data_mtcars,
    "mtcars.csv",
    format = "file"
  )
  ,tar_target(
    data_iris,
    data("iris")
  )
  ,tar_target(
    summary_iris,
    slow_summary(data_iris)
  )
  ,tar_target(
    data_mtcars,
    read.csv(path_data_mtcars)
  )
  ,tar_target(
    summary_mtcars,
    slow_summary(data_mtcars)
  ),
  tar_target(
    list_summaries,
    list(
      "summary_iris" = summary_iris,
      "summary_mtcars" = summary_mtcars
    )
  )
  ,tar_target(
    plot_mtcars,
    save_plot(
      filename = "mtcars_plot.png", data_mtcars
    ), format = "file"
  )
)
# rendering docs

list(
  tar_target(
    path_data_mtcars,
    "mtcars.csv", format = "file"
  )
  ,tar_target(
    data_mtcars,
    read.csv(path_data_mtcars)
  )
  ,tar_target(
    summary_mtcars,
    skim(data_mtcars)
  )
  ,tar_target(
    clean_mtcars,
    mutate(data_mtcars, am = as.character(am))
  )
  ,tar_target(
    plot_mtcars,
    {ggplot(clean_mtcars) + 
        geom_point(aes(y = mpg, x = hp, shape = am))}
  )
  # render to .Rmd - you have to create the Rmd file in root dir
  ,tar_render(
    my_doc,
    "my_doc.Rmd"
  )
)


