/*
 * SoapUI, Copyright (C) 2004-2022 SmartBear Software
 *
 * Licensed under the EUPL, Version 1.1 or - as soon as they will be approved by the European Commission - subsequent 
 * versions of the EUPL (the "Licence"); 
 * You may not use this work except in compliance with the Licence. 
 * You may obtain a copy of the Licence at: 
 * 
 * http://ec.europa.eu/idabc/eupl 
 * 
 * Unless required by applicable law or agreed to in writing, software distributed under the Licence is 
 * distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either 
 * express or implied. See the Licence for the specific language governing permissions and limitations 
 * under the Licence. 
 */

package com.eviware.soapui.actions;

import com.eviware.soapui.SoapUI;
import com.eviware.soapui.analytics.Analytics;
import com.eviware.soapui.impl.WorkspaceImpl;
import com.eviware.soapui.model.project.Project;
import com.eviware.soapui.model.workspace.Workspace;
import com.eviware.soapui.model.workspace.WorkspaceListener;
import com.eviware.soapui.support.action.support.AbstractSoapUIAction;

import javax.swing.*;

import static com.eviware.soapui.analytics.SoapUIActions.SWITCH_THEME;

/**
 * Action to switch dark or light mode
 *
 * @author rrivero
 */

public class SwitchThemeAction extends AbstractSoapUIAction<WorkspaceImpl> implements WorkspaceListener {
    public static final String SOAPUI_ACTION_ID = "SwitchThemeAction";

    public SwitchThemeAction() {
        super("Switch theme", "Switches theme");

        Workspace workspace = SoapUI.getWorkspace();
        if (workspace == null) {
            setEnabled(true);
        } else {
            setEnabled(workspace.getProjectCount() > 0);
            workspace.addWorkspaceListener(this);
        }
    }

    public void perform(WorkspaceImpl workspace, Object param) {
        try {
            boolean currentDarkModeState = SoapUI.getSettings().getBoolean("UISettings.DARK_MODE", false);
            boolean newDarkModeState = !currentDarkModeState;

            // Ask for confirmation before making the change
            SwingUtilities.invokeLater(() -> {
                String[] options = { "Yes", "No" };
                int result = JOptionPane.showOptionDialog(
                        SoapUI.getFrame(),
                        "Switch to " + (newDarkModeState ? "dark" : "light") + " mode?\n" +
                                "The application will restart to apply the theme changes.",
                        "Switch Theme",
                        JOptionPane.YES_NO_OPTION,
                        JOptionPane.QUESTION_MESSAGE,
                        null,
                        options,
                        options[0]);

                if (result == 0) { // "Yes" selected
                    try {
                        // Save the new theme setting
                        SoapUI.getSettings().setBoolean("UISettings.DARK_MODE", newDarkModeState);
                        SoapUI.saveSettings();

                        // Force restart
                        restartApplication();

                        Analytics.trackAction(SWITCH_THEME);
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                }
                // If "No" is selected or dialog is closed, do nothing
            });
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private void restartApplication() {
        SwingUtilities.invokeLater(() -> {
            try {
                // Save all settings and workspace before restarting
                SoapUI.getSoapUICore().saveSettings();
                if (SoapUI.getWorkspace() != null) {
                    SoapUI.getWorkspace().onClose();
                }

                // Try to restart the application using different methods
                if (tryRestartWithJavaCommand()) {
                    return;
                }

                // If restart methods fail, just exit gracefully
                // The user will need to manually restart
                System.exit(0);

            } catch (Exception e) {
                // If anything fails, just exit
                System.exit(0);
            }
        });
    }

    private boolean tryRestartWithJavaCommand() {
        try {
            // Get the main arguments to restart with same parameters
            String[] args = SoapUI.getMainArgs();

            // Get current JVM properties
            String java = System.getProperty("java.home") + "/bin/java";
            String classpath = System.getProperty("java.class.path");
            String mainClass = "com.eviware.soapui.SoapUI";

            // Build the command to restart the application
            java.util.List<String> command = new java.util.ArrayList<>();
            command.add(java);
            command.add("-cp");
            command.add(classpath);
            command.add(mainClass);

            // Add original arguments if any
            if (args != null) {
                for (String arg : args) {
                    command.add(arg);
                }
            }

            // Start the new process
            ProcessBuilder builder = new ProcessBuilder(command);
            builder.start();

            // Exit current application
            System.exit(0);
            return true;

        } catch (Exception e) {
            return false;
        }
    }

    public void projectAdded(Project project) {
        setEnabled(true);
    }

    public void projectChanged(Project project) {
    }

    public void projectRemoved(Project project) {
        setEnabled(project.getWorkspace().getProjectCount() == 0);
    }

    public void workspaceSwitched(Workspace workspace) {
        setEnabled(workspace.getProjectCount() > 0);
    }

    public void workspaceSwitching(Workspace workspace) {
    }

    @Override
    public void projectClosed(Project project) {
    }

    @Override
    public void projectOpened(Project project) {
    }
}
