# shiny-app/app.R
# Interactive nomogram explorer — WIP placeholder.
# Will dial AGE, BASELINE_PAIN, SEX, LEDD, UPDRS-III and predict 24-month
# Δ Pain trajectory from the model artefact in outputs/objects/nomogram_model.rds.

library(shiny)
library(ggplot2)

ui <- fluidPage(
  titlePanel("PPMI DBS pain nomogram explorer (WIP)"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("age", "Age at baseline", 40, 85, value = 62),
      sliderInput("ledd", "LEDD (mg)", 0, 2500, value = 600),
      sliderInput("updrs3", "MDS-UPDRS-III", 0, 80, value = 25),
      sliderInput("pain0", "Baseline NP1PAIN", 0, 4, value = 1),
      selectInput("sex", "Sex", c("M", "F"))
    ),
    mainPanel(
      h4("Predicted 24-month Δ Pain trajectory by arm"),
      plotOutput("traj"),
      tags$small("Demo only — research use only.")
    )
  )
)

server <- function(input, output) {
  output$traj <- renderPlot({
    # Placeholder: a horizontal-line plot until the real model is wired in.
    ggplot(data.frame(t = 0:24, y = 0)) +
      aes(t, y) + geom_hline(yintercept = 0, linetype = "dashed") +
      scale_y_continuous("Predicted Δ Pain", limits = c(-2, 2)) +
      labs(x = "Months since anchor",
           title = "Placeholder — pipeline integration pending") +
      theme_classic(base_size = 14)
  })
}

shinyApp(ui, server)
