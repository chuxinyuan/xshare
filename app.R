
# 注意：密钥需要转为PEM格式
# 代码：ssh-keygen -p -m PEM -f ~/.ssh/id_rsa

# Linux 需要安装 libgit2:
# Debian: libgit2-dev
# Fedora / CentOS: libgit2-devel
# Arch Linux libgit2

#------------------------------------------------------------------------------#
#                               博客本地仓库、URL
#------------------------------------------------------------------------------#

# Sys.setlocale(category = "LC_ALL", locale = "zh_CN.UTF-8")
local_repo = "../xmin"
blog_url = "https://xmin.netlify.app"

#------------------------------------------------------------------------------#
#                              加载相关 R 包
#------------------------------------------------------------------------------#

library(shiny)
library(shinydashboard)

#------------------------------------------------------------------------------#
#                             定义前端交互界面
#------------------------------------------------------------------------------#

ui = dashboardPage(

  skin = "blue",
  dashboardHeader(
    title = "文件上传分享",
    titleWidth = 260
  ),

  dashboardSidebar(
    width = 260,
    collapsed = TRUE,
    sidebarMenu(
      menuItem(
        "开始使用",
        tabName = "start",
        icon = icon("rocket")
      )
    )
  ),

  dashboardBody(
    tabItems(
      tabItem(
        tabName = "start",
        fluidPage(
          br(),
          fluidPage(
            fileInput(
              inputId = "choose_file",
              label = "选择上传文件",
              buttonLabel = "浏览...",
              placeholder = "没有选择文件",
              width = "300px"
            ),
            actionButton(
              inputId = "button_prepare",
              label = "准备文件",
              icon = icon("table"),
              width = "300px",
              class = "btn-primary btn-md"
            ),
            tableOutput("filelist")
          ),
          br(),
          fluidPage(
            actionButton(
              inputId = "button_upload",
              label = "上传文件",
              width = "300px",
              icon = icon("file-upload"),
              class = "btn-primary btn-md"
            ),
            tableOutput("uploadfile")
          )
        )
      )
    )
  )

)

#------------------------------------------------------------------------------#
#                             定义后台服务逻辑
#------------------------------------------------------------------------------#

server = function(input, output, session) {
  
  # 创建对象来存储结果
  values = reactiveValues()
  
  #----------------------------------------------------------------------------#
  
  # 准备文件
  observeEvent(input$button_prepare, {
    
    ## 生成存放数据路径
    current_time = format(Sys.time(), format = "%Y%m%d%H%M%S")
    src = paste("./data", current_time, sep = "/")
    if (!dir.exists(src)) dir.create(src, recursive = TRUE)
    values$src = src
    ## 选择上传文件后将文件放在制定的路径下
    file.copy(
      input$choose_file$datapath,
      file.path(src, input$choose_file$name),
      overwrite = TRUE
    )
    output$filelist = renderTable(
      print(list.files(src, full.names = TRUE)),
      colnames = FALSE
    )
    
  })
  
  #----------------------------------------------------------------------------#
  
  # 上传文件
  observeEvent(input$button_upload, {
    
    ## 定义要上传到 GitLab 上的文件
    file = input$choose_file$name
    src = values$src
    file_from = file.path(src, file)
    
    ## 把要上传的文件复制到本地指定目录下
    img_ext = c(
      "png", "PNG", "jpg", "JPG", "jpeg", "JPEG", "bmp",
      "BMP", "svg", "SVG", "ico", "ICO", "tif", "TIF",
      "gif", "GIF", "webp", "WEBP", "tiff", "TIFF"
    )
    if (tools::file_ext(input$choose_file$name) %in% img_ext) {
      dest_dir = "images"
    } else {
      dest_dir = "source"
    }
    file_add = file.path(local_repo, "static", dest_dir, file)
    file.copy(file_from, file_add)
    Sys.sleep(2)
    
    ## 推送文件到 GitLab 指定仓库
    git2r::add(local_repo, file_add)
    git2r::commit(local_repo, paste("upload", file, sep = " "))
    git2r::push(
      object = local_repo,
      name = "origin",
      refspec = "refs/heads/master",
      credentials = git2r::cred_ssh_key(),
      set_upstream = TRUE
    )
    
    ## 生成图片的 URL 地址
    file_url = file.path(blog_url, dest_dir, file)
    
    ## 反馈文件的 URL
    output$uploadfile = renderTable(
      print(file_url),
      colnames = FALSE
    )
    
  })

}

#------------------------------------------------------------------------------#
#                                运行 ShinyApp
#------------------------------------------------------------------------------#

shinyApp(ui = ui, server = server)

#------------------------------------------------------------------------------#
