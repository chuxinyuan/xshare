
local_repo = "../xmin"
blog_url = "https://xmin.netlify.app"

file_name = "Blue_flower_by_Elena_Stravoravdi.jpg"
file_path = "E:/Picture/桌面壁纸/Blue_flower_by_Elena_Stravoravdi.jpg"

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

git2r::add(local_repo, file_add)
git2r::commit(local_repo, paste("upload", file_name, sep = " "))
git2r::push(
  object = local_repo,
  name = "origin",
  refspec = "refs/heads/master",
  credentials = git2r::cred_ssh_key(
    publickey = ssh_path("id_ed25519.pub"),
    privatekey = ssh_path("id_ed25519"),
    passphrase = character(0)
  ),
  set_upstream = TRUE
)