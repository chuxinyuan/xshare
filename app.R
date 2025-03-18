
#------------------------------------------------------------------------------#
#                                注意事项
#------------------------------------------------------------------------------#

# 注意：密钥需要转为PEM格式
# 代码：ssh-keygen -p -m PEM -f ~/.ssh/id_rsa

# Linux 系统需要安装 libgit2:
# Debian: libgit2-dev
# Fedora / CentOS: libgit2-devel
# Arch Linux: libgit2

#------------------------------------------------------------------------------#
#                               配置环境变量
#------------------------------------------------------------------------------#

# Sys.setlocale(category = "LC_ALL", locale = "zh_CN.UTF-8")
local_repo = "../xmin"
blog_url = "https://xmin.netlify.app"

#------------------------------------------------------------------------------#
#                             定义前端交互界面
#------------------------------------------------------------------------------#

library(shiny)
ui = fluidPage(
  fluidRow(
    column(
      width = 6, 
      offset = 3,
      br(),
      br(),
      br(),
      wellPanel(
        fileInput(
          inputId = "choose_file",
          label = "选择上传文件",
          buttonLabel = "浏览...",
          placeholder = "没有选择文件"
        ),
        div(
          style = "display: inline-block;
                   width: 100%;
                   text-align: center;",
          actionButton(
            inputId = "upload_file",
            label = "上传文件",
            class = "btn-success",
          )
        ),
        br(),
        tableOutput("file_url"),
        br()
      )
    )
  )
)

#------------------------------------------------------------------------------#
#                             定义后台服务逻辑
#------------------------------------------------------------------------------#

server = function(input, output, session) {
  
  # 上传文件
  observeEvent(input$upload_file, {
    
    ## 定义要上传到 GitLab 上的文件
    file = input$choose_file
    file_name = file$name
    file_path = file$datapath
    
    ## 把要上传的文件复制到本地指定目录下
    img_ext = c(
      "png", "PNG", "jpg", "JPG", "jpeg", "JPEG", "bmp",
      "BMP", "svg", "SVG", "ico", "ICO", "tif", "TIF",
      "gif", "GIF", "webp", "WEBP", "tiff", "TIFF"
    )
    ext = tools::file_ext(file_name)
    if (ext %in% img_ext) {
      dest_dir = "images"
    } else {
      dest_dir = "source"
    }
    file_add = file.path(local_repo, "static", dest_dir, file_name)
    file.copy(file_path, file_add)
    Sys.sleep(2)
    
    ## 推送文件到 GitHub 指定仓库
    git2r::add(local_repo, file_add)
    git2r::commit(local_repo, paste("upload", file_name, sep = " "))
    git2r::push(
      object = local_repo,
      name = "origin",
      refspec = "refs/heads/master",
      credentials = git2r::cred_ssh_key(
        publickey = git2r::ssh_path("id_ed25519.pub"),
        privatekey = git2r::ssh_path("id_ed25519"),
        passphrase = character(0)
      ),
      set_upstream = TRUE
    )
    
    ## 生成图片的 URL 地址
    file_url = file.path(blog_url, dest_dir, file_name)
    
    ## 反馈文件的 URL
    output$file_url = renderTable(
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
