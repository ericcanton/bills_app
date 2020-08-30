#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinyWidgets)
library(data.table)
library(DT)
library(lubridate)

usual_bills_csv = "usual.csv"
paid_bills_ledger = "ledger.csv"

ui <- fluidPage(
  title = "Bills App",
  tags$head(
    tags$style(HTML("hr {border-top: 1px solid #2e2d2b;}"))
  ),
  
  sidebarLayout(
    
    sidebarPanel({
      list(
        materialSwitch("displayBillManagement", label = tags$h4("Bill Management"), right = FALSE, inline = TRUE),
        conditionalPanel("input.displayBillManagement",
                         radioGroupButtons("billRadio", 
                                           label = NULL,
                                           choiceNames = c("Pay", "Create New"),
                                           choiceValues = c("pay", "new"),
                                           justified = TRUE),
                         conditionalPanel("input.billRadio == 'new'", 
                                          column(12, uiOutput("createBill"))),
                         conditionalPanel("input.billRadio == 'pay'", 
                                          column(12, uiOutput("payBillSelect"), uiOutput("payBill"))),
        ),
        tags$hr(),
        br(),
        uiOutput("upcomingBills")
      )
    }),
    
    mainPanel(
      DT::DTOutput("ledger", width = "100%")
    )
    
  )
)

server <- function(input, output, session) {
  
  shared <- reactiveValues()
  
  bill_hint <- function(lineitem) {
    HTML(
      paste(
        paste("<b>Company:</b>", lineitem$company),
        paste("<b>Bill Name:</b>", lineitem$name),
        paste("<b>Due date:</b>", lineitem$due),
        paste("<b>Cost:</b>", lineitem$cost),
        "<br/>",
        sep="<br/>"
      )
    )
  }
  
  known_bills <- reactive({
    if (is.null(shared$bills)) return()
    
    paste(shared$bills[['company']], shared$bills[['name']], sep = " :: ")
  })
  
  output$upcomingBills <- renderUI({
    shared$upcoming <- fread(file = usual_bills_csv, header = TRUE)
    today <- Sys.Date()
    
    # Figure out the order of the upcoming bills
    upcoming <- shared$upcoming
    todayDayOfMonth <- mday(today)
    todayMonth <- month(today)
    todayYear <- year(today)
    
    billsToday <- upcoming[dom == todayDayOfMonth]
    billsToday[, due := today]
    
    billsThisMonth <- upcoming[dom > todayDayOfMonth]
    billsThisMonth <- billsThisMonth[order(dom)]
    bdom <- billsThisMonth[['dom']]
    due <- ymd(sapply(bdom, function(x) paste(todayYear, todayMonth, x, sep = "-")))
    billsThisMonth[, `due` := (due)]
    
    billsNextMonth <- upcoming[dom < todayDayOfMonth]
    billsNextMonth <- billsNextMonth[order(dom)]
    bdom <- billsNextMonth[['dom']]
    due <- ymd(sapply(bdom, function(x) paste(todayYear, todayMonth, x, sep = "-"))) %m+% months(1) # add one month to these Y-m-d Dates
    billsNextMonth[, `due` := (due)]
    
    bills <- rbind(billsThisMonth, billsNextMonth)
    shared$bills <- rbind(billsToday, bills) # used in pay/delete mechanism
    
    list(
      tags$h3("Upcoming bills"),
      tags$h4(HTML("&#9733; Today's Bills")),
      HTML(if (nrow(billsToday) > 0) unlist(lapply(seq(nrow(billsToday)), function(i) bill_hint(billsToday[i]))) else "None!"),
      tags$h4(HTML("&#9733; Bills in the next month")),
      HTML(if (nrow(bills) > 0) {unlist(lapply(seq(nrow(bills)), function(i) bill_hint(bills[i])))} else {"None!"})
    )
  })
  
  output$createBill <- renderUI({
    list(
      textInput("billCompany", label = "Company", placeholder = "BetterDeal & Co."),
      textInput("billName", label = "Description/Name", placehold = "Auto Insurance"),
      textInput("billCost", label = "Cost", placeholder = "5.00"),
      dateInput("billDate", label = "Next due date", value = Sys.Date()),
      actionButton("createBillButton", label = "Create")
    )
  })
     
  output$payBillSelect <- renderUI({
    selectInput("payWhichBill", label = NULL, choices = known_bills(), selected = known_bills()[1])
  })
      
  output$payBill <- renderUI({
    # reactive hook
    if (is.null(input$payWhichBill))
      return()
    
    id <- unlist(strsplit(isolate(input$payWhichBill), " :: "))
    billLine <- shared$bills[company == id[1] & name == id[2]]
    list(
      textInput("payBillCompany", label = "Company", value = billLine[['company']]),
      textInput("payBillName", label = "Description/Name", value = billLine[['name']]),
      textInput("payBillCost", label = "Paid", value = billLine[['cost']]),
      dateInput("payBillDueDate", label = "Due date", value = billLine[['due']]),
      dateInput("payBillPaidDate", label = "Paid date", value = Sys.Date()),
      actionButton("payBillButton", label = "Pay")
    )
  })
  
  output$ledger <- DT::renderDT({
    billLedger <- fread(file = paid_bills_ledger)
    #browser()
    billLedger <- billLedger[order(`Date Paid`, decreasing = TRUE)]
    
    shared$billLedger <- billLedger
    
    datatable(billLedger, filter = "top")
  })
  
  observeEvent(input$payBillButton, {
    justGotPaid <- data.table("Bill Name" = input$payBillName,
                              "Company" = input$payBillCompany,
                              "Date Paid" = as.IDate(input$payBillPaidDate),
                              "Due Date" = as.IDate(input$payBillDueDate),
                              "Amount Paid" = as.numeric(input$payBillCost))
    shared$billLedger <- rbind(justGotPaid, shared$billLedger)
    fwrite(shared$billLedger, file = paid_bills_ledger, quote = TRUE)
  })
  
  observeEvent(input$createBillButton, {
    newBill <- data.table("name" = input$billName,
                          "company" = input$billCompany,
                          "dom" = mday(input$billDate),
                          "cost" = input$billCost, 
                          "freq" = "month")
    
    shared$upcoming <- rbind(shared$upcoming, newBill)
    fwrite(shared$upcoming, file = usual_bills_csv, quote = TRUE)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
