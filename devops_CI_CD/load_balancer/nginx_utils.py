import subprocess
import platform
import os
import shutil

def is_nginx_installed():
    return shutil.which("nginx") is not None or shutil.which("nginx.exe") is not None

def install_nginx():
    os_name = platform.system()
    if os_name == "Linux" or "microsoft" in platform.uname().release.lower():
        print("[+] Attempting to install NGINX...")
        subprocess.run(["sudo", "apt-get", "update"], check=True)
        subprocess.run(["sudo", "apt-get", "install", "-y", "nginx"], check=True)
    elif os_name == "Windows":
        print("[!] Please install NGINX manually on Windows:")
        print("    https://nginx.org/en/download.html")
        raise RuntimeError("Manual install required on Windows.")
    else:
        raise RuntimeError(f"Unsupported OS: {os_name}")

def start_nginx():
    if not is_nginx_installed():
        print("[!] NGINX not found.")
        try:
            install_nginx()
        except Exception as e:
            print("[✗] Could not install NGINX:", e)
            return

    nginx_exec = "nginx.exe" if platform.system() == "Windows" else "nginx"
    config_path = os.path.abspath("./nginx/default.conf")
    nginx_root = os.path.abspath("./nginx")

    print("[+] Starting NGINX...")
    try:
        subprocess.run([
            nginx_exec,
            "-c", config_path,
            "-p", nginx_root
        ], check=True)
        print("[✓] NGINX started.")
    except subprocess.CalledProcessError as e:
        print("[!] Error starting NGINX:", e)

def reload_nginx():
    print("[~] Reloading NGINX...")
    try:
        subprocess.run(["nginx", "-s", "reload"], check=True)
        print("[✓] Reloaded.")
    except Exception as e:
        print("[!] Reload failed:", e)

def update_nginx_conf(primary_ip, backup_ip):
    template_path = "./templates/default_template.conf"
    output_path = "./nginx/default.conf"

    with open(template_path, "r") as f:
        template = f.read()

    new_conf = template.replace("{{PRIMARY}}", f"{primary_ip}:80")                        .replace("{{BACKUP}}", f"{backup_ip}:80")

    os.makedirs("./nginx", exist_ok=True)

    with open(output_path, "w") as f:
        f.write(new_conf)

    reload_nginx()
