/*
 * SettingsDialog.vala
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

using Gtk;
using Gee;

public class SettingsDialog : Gtk.Dialog {

    private Gtk.CheckButton chk_notify_major;
    private Gtk.CheckButton chk_notify_minor;
    private Gtk.CheckButton chk_notify_bubble;
    private Gtk.CheckButton chk_notify_dialog;
    private Gtk.CheckButton chk_hide_unstable;
    private Gtk.CheckButton chk_hide_older;
    private Gtk.CheckButton chk_hide_older_4;
    private Gtk.CheckButton chk_update_grub_timeout;

    public GtkHelper gtk_helper;

    public SettingsDialog.with_parent (Window parent) {
        gtk_helper = new GtkHelper ();

        set_transient_for (parent);
        set_modal (true);
        set_skip_taskbar_hint (true);
        set_skip_pager_hint (true);
        window_position = WindowPosition.CENTER_ON_PARENT;
        deletable = false;
        resizable = false;

        icon = gtk_helper.get_app_icon (16);

        title = _("Settings");

        // get content area
        var vbox_main = get_content_area ();
        vbox_main.spacing = 6;
        vbox_main.margin = 12;
        vbox_main.width_request = 400;
        vbox_main.height_request = -1;

        // notification
        var label = new Label ("<b>" + _("Notification") + "</b>");
        label.set_use_markup (true);
        label.xalign = (float) 0.0;
        label.margin_bottom = 6;
        vbox_main.add (label);

        // chk_notify_major
        var chk = new Gtk.CheckButton.with_label (_("Notify if a major release is available"));
        chk.active = App.notify_major;
        vbox_main.add (chk);
        chk_notify_major = chk;

        chk.toggled.connect (() => {
            App.notify_major = chk_notify_major.active;
        });

        // chk_notify_minor
        chk = new Gtk.CheckButton.with_label (_("Notify if a point release is available"));
        chk.active = App.notify_minor;
        vbox_main.add (chk);
        chk_notify_minor = chk;

        chk.toggled.connect (() => {
            App.notify_minor = chk_notify_minor.active;
        });

        // show bubble
        chk = new Gtk.CheckButton.with_label (_("Show notification bubble on desktop"));
        chk.active = App.notify_bubble;
        vbox_main.add (chk);
        chk_notify_bubble = chk;

        chk.toggled.connect (() => {
            App.notify_bubble = chk_notify_bubble.active;
        });

        // show window
        chk = new Gtk.CheckButton.with_label (_("Show notification dialog"));
        chk.active = App.notify_dialog;
        chk.margin_bottom = 6;
        vbox_main.add (chk);
        chk_notify_dialog = chk;

        chk.toggled.connect (() => {
            App.notify_dialog = chk_notify_dialog.active;
        });

        // notification interval
        var hbox = new Gtk.Box (Orientation.HORIZONTAL, 6);
        vbox_main.add (hbox);

        label = new Label (_("Check every"));
        label.xalign = (float) 0.0;
        hbox.add (label);

        var adjustment = new Gtk.Adjustment (App.notify_interval_value, 1, 52, 1, 1, 0);
        var spin = new Gtk.SpinButton (adjustment, 1, 0);
        spin.xalign = (float) 0.5;
        hbox.add (spin);
        var spin_notify = spin;

        spin.changed.connect (() => {
            App.notify_interval_value = (int) spin_notify.get_value ();
        });

        // combo
        var combo = new Gtk.ComboBox ();
        var cell_text = new Gtk.CellRendererText ();
        combo.pack_start (cell_text, false);
        combo.set_attributes (cell_text, "text", 0);
        hbox.add (combo);

        combo.changed.connect (() => {
            App.notify_interval_unit = combo.active;
            // log_debug("combo: %lf".printf(combo.active));
        });

        // populate
        TreeIter iter;
        var model = new Gtk.ListStore (2, typeof (string), typeof (string));
        model.append (out iter);
        model.set (iter, 0, _("Hour(s)"), 1, "hour");
        model.append (out iter);
        model.set (iter, 0, _("Day(s)"), 1, "day");
        model.append (out iter);
        model.set (iter, 0, _("Week(s)"), 1, "week");
        combo.set_model (model);
        combo.set_active (App.notify_interval_unit);

        // display
        label = new Label ("<b>" + _("Display") + "</b>");
        label.set_use_markup (true);
        label.xalign = (float) 0.0;
        label.margin_top = 12;
        label.margin_bottom = 6;
        vbox_main.add (label);

        // chk_hide_unstable
        chk = new CheckButton.with_label (_("Hide unstable and RC releases"));
        chk.active = LinuxKernel.hide_unstable;
        vbox_main.add (chk);
        chk_hide_unstable = chk;

        chk.toggled.connect (() => {
            LinuxKernel.hide_unstable = chk_hide_unstable.active;
        });

        // chk_hide_older
        chk = new CheckButton.with_label (_("Hide kernels older than 5.0"));
        chk.active = LinuxKernel.hide_older;
        vbox_main.add (chk);
        chk_hide_older = chk;

        chk.toggled.connect (() => {
            LinuxKernel.hide_older = chk_hide_older.active;

            // also check hide_older_4 since nothing older than 5 will be shown
            if (chk_hide_older.active) {
                chk_hide_older_4.active = true;
                LinuxKernel.hide_older_4 = chk_hide_older_4.active;
            }
        });

        // chk_hide_older_4
        chk = new CheckButton.with_label (_("Hide kernels older than 4.0"));
        chk.active = LinuxKernel.hide_older_4;
        vbox_main.add (chk);
        chk_hide_older_4 = chk;

        chk.toggled.connect (() => {
            if (chk_hide_older.active) {
                chk_hide_older_4.active = true;
            }

            LinuxKernel.hide_older_4 = chk_hide_older_4.active;
        });

        // grub
        label = new Label ("<b>" + _("GRUB Options") + "</b>");
        label.set_use_markup (true);
        label.xalign = (float) 0.0;
        label.margin_top = 12;
        label.margin_bottom = 6;
        vbox_main.add (label);

        hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        hbox.margin_bottom = 6;
        vbox_main.add (hbox);

        // chk_update_grub_timeout
        chk = new CheckButton.with_label (_("Set GRUB menu timeout"));
        chk.active = LinuxKernel.update_grub_timeout;
        chk.hexpand = true;
        hbox.add (chk);
        chk_update_grub_timeout = chk;

        chk.set_tooltip_text (_("Updates the GRUB menu after installing or removing kernels, so that the menu is displayed for 2 seconds at boot time. This will help you recover from a bad kernel update by selecting another kernel to boot. During boot, use the 'Advanced options for Ubuntu' menu entry to select another kernel.\n\n0 = Do not show menu\n-1 = Show indefinitely till user selects"));

        chk.toggled.connect (() => {
            LinuxKernel.update_grub_timeout = chk_update_grub_timeout.active;
        });

        adjustment = new Gtk.Adjustment (LinuxKernel.grub_timeout, 1, 9999, 1, 1, 0);
        spin = new Gtk.SpinButton (adjustment, 1, 0);
        spin.xalign = (float) 0.5;
        hbox.add (spin);
        var spin_grub = spin;

        spin.set_tooltip_text (_("Time (in seconds) to display the GRUB menu\n\n0 = Do not show menu\n-1 = Show indefinitely till user selects"));

        spin.changed.connect (() => {
            LinuxKernel.grub_timeout = (int) spin_grub.get_value ();
        });

        chk_update_grub_timeout.toggled.connect (() => {
            spin_grub.sensitive = chk_update_grub_timeout.active;
        });

        chk_update_grub_timeout.toggled ();

        // actions -------------------------

        // ok
        var button = new Gtk.Button.with_label (_("Ok"));
        button.width_request = 92;
        button.set_halign (Gtk.Align.END);
        button.clicked.connect (() => {
            this.close ();
        });

        vbox_main.add (button);
        this.destroy.connect (btn_ok_click);
        show_all ();
    }

    private void btn_ok_click () {
        App.save_app_config ();
    }
}
