/*
 * TeeJee.System.vala
 *
 * Copyright 2012-2019 Tony George <teejeetech@gmail.com>
 * Copyright 2019-2020 Joshua Dowding <joshuadowding@outlook.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 */

using GLib;

public class SystemHelper : GLib.Object {

    public SystemHelper () {
    }

    // user ---------------------------------------------------

    public int get_user_id () {

        // returns actual user id of current user (even for applications executed with sudo and pkexec)

        string pkexec_uid = GLib.Environment.get_variable ("PKEXEC_UID");

        if (pkexec_uid != null) {
            return int.parse (pkexec_uid);
        }

        string sudo_user = GLib.Environment.get_variable ("SUDO_USER");

        if (sudo_user != null) {
            return get_user_id_from_username (sudo_user);
        }

        return get_user_id_effective (); // normal user
    }

    public int get_user_id_effective () {
        ProcessHelper process_helper = new ProcessHelper ();

        // returns effective user id (0 for applications executed with sudo and pkexec)

        int uid = -1;
        string cmd = "id -u";
        string std_out, std_err;

        process_helper.exec_sync (cmd, out std_out, out std_err);

        if ((std_out != null) && (std_out.length > 0)) {
            uid = int.parse (std_out);
        }

        return uid;
    }

    public string get_username () {

        // returns actual username of current user (even for applications executed with sudo and pkexec)

        return get_username_from_uid (get_user_id ());
    }

    public string get_username_effective () {

        // returns effective user id ('root' for applications executed with sudo and pkexec)

        return get_username_from_uid (get_user_id_effective ());
    }

    public int get_user_id_from_username (string username) {
        FileHelper file_helper = new FileHelper ();

        int user_id = -1;

        foreach (var line in file_helper.file_read ("/etc/passwd").split ("\n")) {
            var arr = line.split (":");
            if (arr.length < 3) {
                continue;
            }
            if (arr[0] == username) {
                user_id = int.parse (arr[2]);
                break;
            }
        }

        return user_id;
    }

    public string get_username_from_uid (int user_id) {
        FileHelper file_helper = new FileHelper ();
        string username = "";

        foreach (var line in file_helper.file_read ("/etc/passwd").split ("\n")) {
            var arr = line.split (":");
            if (arr.length < 3) {
                continue;
            }
            if (int.parse (arr[2]) == user_id) {
                username = arr[0];
                break;
            }
        }

        return username;
    }

    public string get_user_home (string username = get_username ()) {
        FileHelper file_helper = new FileHelper ();
        string userhome = "";

        foreach (var line in file_helper.file_read ("/etc/passwd").split ("\n")) {
            var arr = line.split (":");
            if (arr.length < 6) {
                continue;
            }
            if (arr[0] == username) {
                userhome = arr[5];
                break;
            }
        }

        return userhome;
    }

    // system ------------------------------------

    // dep: cat TODO: rewrite
    public double get_system_uptime_seconds () {
        LoggingHelper logging_helper = new LoggingHelper ();

        /* Returns the system up-time in seconds */

        string cmd = "";
        string std_out;
        string std_err;
        int ret_val;

        try {
            cmd = "cat /proc/uptime";
            Process.spawn_command_line_sync (cmd, out std_out, out std_err, out ret_val);
            string uptime = std_out.split (" ")[0];
            double secs = double.parse (uptime);
            return secs;
        } catch (Error e) {
            logging_helper.log_error (e.message);
            return 0;
        }
    }

    // internet helpers ----------------------

    public bool check_internet_connectivity () {
        ProcessHelper process_helper = new ProcessHelper ();
        LoggingHelper logging_helper = new LoggingHelper ();

        string std_err, std_out;

        string cmd = "url='https://www.google.com' \n";

        // Note: minimum of 3 seconds is required for timeout, to avoid wrong results

        cmd += "httpCode=$(curl -o /dev/null --silent --max-time 5 --head --write-out '%{http_code}\n' $url) \n";
        cmd += "test $httpCode -lt 400 -a $httpCode -gt 0 \n";
        cmd += "exit $?";

        int status = process_helper.exec_script_sync (cmd, out std_out, out std_err, false);

        if (std_err.length > 0) {
            logging_helper.log_error (std_err);
        }

        if (status != 0) {
            logging_helper.log_error (_("Internet connection is not active"));
        }

        return (status == 0);
    }

    public bool command_exists (string command) {
        ProcessHelper process_helper = new ProcessHelper ();
        string path = process_helper.get_cmd_path (command);
        return ((path != null) && (path.length > 0));
    }

    // open -----------------------------

    public bool xdg_open (string file, string user = "") {
        ProcessHelper process_helper = new ProcessHelper ();
        LoggingHelper logging_helper = new LoggingHelper ();
        FileHelper file_helper = new FileHelper ();

        string path = process_helper.get_cmd_path ("xdg-open");

        if ((path != null) && (path != "")) {

            string cmd = "xdg-open '%s'".printf (file_helper.escape_single_quote (file));

            if (user.length > 0) {
                cmd = "pkexec --user %s env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY ".printf (user) + cmd;
            }

            logging_helper.log_debug (cmd);

            int status = process_helper.exec_script_async (cmd);

            return (status == 0);
        }

        return false;
    }

    // timers --------------------------------------------------

    public GLib.Timer timer_start () {
        var timer = new GLib.Timer ();
        timer.start ();
        return timer;
    }

    public void timer_restart (GLib.Timer timer) {
        timer.reset ();
        timer.start ();
    }

    public ulong timer_elapsed (GLib.Timer timer, bool stop = true) {
        ulong microseconds;
        double seconds;
        seconds = timer.elapsed (out microseconds);
        if (stop) {
            timer.stop ();
        }
        return (ulong) ((seconds * 1000) + (microseconds / 1000));
    }

    public void sleep (int milliseconds) {
        Thread.usleep ((ulong) milliseconds * 1000);
    }

    public string timer_elapsed_string (GLib.Timer timer, bool stop = true) {
        ulong microseconds;
        double seconds;
        seconds = timer.elapsed (out microseconds);
        if (stop) {
            timer.stop ();
        }
        return "%.0f ms".printf ((seconds * 1000) + microseconds / 1000);
    }

    public void timer_elapsed_print (GLib.Timer timer, bool stop = true) {
        LoggingHelper logging_helper = new LoggingHelper ();

        ulong microseconds;
        double seconds;
        seconds = timer.elapsed (out microseconds);

        if (stop) {
            timer.stop ();
        }
        logging_helper.log_msg ("%s %lu\n".printf (seconds.to_string (), microseconds));
    }

    public void set_numeric_locale (string type) {
        Intl.setlocale (GLib.LocaleCategory.NUMERIC, type);
        Intl.setlocale (GLib.LocaleCategory.COLLATE, type);
        Intl.setlocale (GLib.LocaleCategory.TIME, type);
    }
}
