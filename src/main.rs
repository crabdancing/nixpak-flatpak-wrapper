use std::{env, path::PathBuf, process::Command};

use env_logger::Env;
use log::debug;
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
struct Config {
    perms: Vec<AppEntry>,
}

#[derive(Serialize, Deserialize, Debug)]
struct AppEntry {
    app_name: String,
    #[serde(rename = "bind_rw", default)]
    bind_rw: Vec<PathBuf>,
    #[serde(rename = "bind_ro", default)]
    bind_ro: Vec<PathBuf>,
}

fn resolve_path(mut path: &mut PathBuf, home_dir: &PathBuf) {
    // Dunno if we should expand ~?
    // Might as well.
    let my_path = path.clone();
    let my_path = if path.starts_with("~") {
        home_dir
            .to_owned()
            .join(my_path.iter().skip(1).collect::<PathBuf>())
    } else {
        my_path
    };
    let mut my_path = match path.canonicalize() {
        Ok(canon_path) => canon_path,
        Err(_) => my_path,
    };

    std::mem::swap(&mut my_path, &mut path);
}

fn main() {
    env_logger::init_from_env(Env::new());
    let home_dir = PathBuf::from(env::var("HOME").expect("Failed to get HOME directory!"));
    let args: Vec<_> = env::args().skip(1).collect();

    let config_str = std::fs::read_to_string("/etc/flatpak-nixpak-wrapper.toml")
        .expect("Failed to read config!");

    let mut config: Config = toml::from_str(&config_str).expect("Failed to deserialize config");

    for app in &mut config.perms {
        for rw_perm in &mut app.bind_rw {
            resolve_path(rw_perm, &home_dir);
        }
        for ro_perm in &mut app.bind_ro {
            resolve_path(ro_perm, &home_dir);
        }
    }

    let mut info_mode = false;
    let mut path = PathBuf::new();
    let mut app_name = String::new();

    for (i, arg) in args.iter().enumerate() {
        match i {
            0 => {
                if arg == "info" {
                    info_mode = true;
                }
            }
            _ => {
                if arg.starts_with("--file-access=") {
                    path.clone_from(&arg.split_once("=").unwrap().1.into());
                } else {
                    app_name = arg.clone();
                }
            }
        }
    }

    debug!("info_mode: {:?}", &info_mode);
    debug!("path: {:?}", &path);
    debug!("app_name {:?}", &app_name);

    resolve_path(&mut path, &home_dir);
    debug!("Resolved path: {:?}", &path);

    let mut output = String::new();

    if info_mode {
        let mut accepted_perms = config.perms.iter().filter(|x| x.app_name == app_name);
        match accepted_perms.next() {
            Some(first_accepted_perm) => {
                debug!("Found accepted perm: {:?}", &first_accepted_perm);
                if first_accepted_perm.bind_rw.contains(&path) {
                    output = "read-write".into();
                } else if first_accepted_perm.bind_ro.contains(&path) {
                    output = "read-only".into();
                } else {
                    output = "hidden".into();
                }
            }
            None => {}
        }
    }
    if output.is_empty() {
        Command::new("flatpak")
            .args(&args)
            .spawn()
            .expect("No failure");
    } else {
        println!("{}", output);
    }
}
