use std::{
    collections::VecDeque,
    env,
    fs::{self, File},
    os,
    path::PathBuf,
    process::Command,
    time::SystemTime,
};

use chrono::Local;
use env_logger::Env;
use log::{debug, error, info};
use serde::{Deserialize, Serialize};
use snafu::{whatever, OptionExt, ResultExt, Whatever};

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

fn resolve_path(mut path: &mut PathBuf, home_dir: &PathBuf, canonicalize: bool) {
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
    let mut my_path = if canonicalize {
        match path.canonicalize() {
            Ok(canon_path) => canon_path,
            Err(_) => my_path,
        }
    } else {
        my_path
    };

    std::mem::swap(&mut my_path, &mut path);
}

fn setup_logger(log_path: &PathBuf) -> Result<(), fern::InitError> {
    fern::Dispatch::new()
        .format(|out, message, record| {
            out.finish(format_args!(
                "[{} {} {}] {}",
                Local::now().to_rfc3339(),
                record.level(),
                record.target(),
                message
            ))
        })
        .level(log::LevelFilter::Debug)
        // .chain(std::io::stdout())
        .chain(fern::log_file(log_path)?)
        .apply()?;
    Ok(())
}

fn app(args: &mut VecDeque<String>) -> Result<(), Whatever> {
    let home_dir =
        PathBuf::from(env::var("HOME").with_whatever_context(|_| "Failed to get HOME directory!")?);

    debug!("Arguments: {:?}", &args);

    let mut self_path = PathBuf::from(args.pop_front().with_whatever_context(|| {
        "How is there no initial (self path) arg? What OS are you on?"
    })?);
    resolve_path(&mut self_path, &home_dir, true);
    let mut wrapped_path =
        which::which("flatpak").with_whatever_context(|_| "Failed to find flatpak in PATH")?;
    resolve_path(&mut wrapped_path, &home_dir, true);

    debug!("self_path: {:?}", &self_path);
    debug!("wrapped_path: {:?}", &wrapped_path);

    if self_path == wrapped_path {
        error!("Misconfiguration would cause infinite loop! The `flatpak` selection in PATH points to this binary! Terminating IMMEDIATELY!");
        panic!("Misconfiguration would cause infinite loop! The `flatpak` selection in PATH points to this binary! Terminating IMMEDIATELY!");
    }

    let config_path = PathBuf::from("/etc/nixpak-flatpak-wrapper.toml");
    let config_str = std::fs::read_to_string(&config_path)
        .with_whatever_context(|_| "Failed to read config!")?;

    let mut config: Config =
        toml::from_str(&config_str).with_whatever_context(|_| "Failed to deserialize config")?;

    for app in &mut config.perms {
        for rw_perm in &mut app.bind_rw {
            resolve_path(rw_perm, &home_dir, false);
        }
        for ro_perm in &mut app.bind_ro {
            resolve_path(ro_perm, &home_dir, false);
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
                    path.clone_from(
                        &arg.split_once("=")
                            .with_whatever_context(|| "What tf even happened here?")?
                            .1
                            .into(),
                    );
                } else {
                    app_name = arg.clone();
                }
            }
        }
    }

    debug!("info_mode: {:?}", &info_mode);
    debug!("path: {:?}", &path);
    debug!("app_name {:?}", &app_name);

    resolve_path(&mut path, &home_dir, true);
    debug!("Resolved path: {:?}", &path);

    let mut output = String::new();

    if !info_mode {
        whatever!("Not in info mode. No action required");
    }
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

    if output.is_empty() {
        whatever!("No output to give");
    }

    println!("{}", output);
    debug!("Gave output: {}", output);

    Ok(())
}

fn main() {
    let mut log_file = dirs::data_local_dir().expect("Could not get data local dir");
    log_file.push("nixpak-flatpak-wrapper");
    fs::create_dir_all(&log_file).expect("Failed to create my data local dir");
    log_file.push("nixpak-flatpak-wrapper.log");

    setup_logger(&log_file).expect("Failed to setup logging");
    debug!("Init");
    let mut args = env::args().collect();

    match app(&mut args) {
        Ok(()) => {}

        Err(e) => {
            info!("{}", e);
            Command::new("flatpak")
                .args(&args)
                .spawn()
                .expect("No failure");
        }
    }
}
