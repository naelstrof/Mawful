using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.IO;
#if UNITY_EDITOR
using UnityEditor.AddressableAssets;
using UnityEditor.AddressableAssets.Settings;
using UnityEditor;
//using UnityEngine.AddressableAssets/Mawful.Initialization;
//using UnityEngine.Localization;

public class Build {
    static string[] scenes = {"Assets/Scenes/MainMenu.unity", "Assets/Scenes/City.unity", "Assets/Scenes/ScoreScreen.unity" };
    private static string outputDirectory {
        get {
            string dir = Environment.GetEnvironmentVariable("BUILD_DIR");
            return dir.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        }
    }
    [MenuItem("Mawful/BuildLinux")]
    static void BuildLinux() {
        //EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Standalone, BuildTarget.StandaloneLinux64);
        EditorUserBuildSettings.SetPlatformSettings("Standalone", "CopyPDBFiles", "true");
        //AddressableAssetSettings.CleanPlayerContent(AddressableAssetSettingsDefaultObject.Settings.ActivePlayerDataBuilder);
        AddressableAssetSettings.CleanPlayerContent();
        AddressableAssetSettings.BuildPlayerContent();
        GetBuildVersion();
        string output = outputDirectory+"Mawful";
        Debug.Log("#### BUILDING TO " + output + " ####");
        var report = BuildPipeline.BuildPlayer(scenes, output, BuildTarget.StandaloneLinux64, BuildOptions.Development);
        Debug.Log("#### BUILD " + output + " DONE ####");
        Debug.Log(report.summary);
    }

    [MenuItem("Mawful/BuildMac")]
    static void BuildMac() {
        //EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Standalone, BuildTarget.StandaloneOSX);
        EditorUserBuildSettings.SetPlatformSettings("Standalone", "CopyPDBFiles", "true");
        AddressableAssetSettings.CleanPlayerContent();
        AddressableAssetSettings.BuildPlayerContent();
        GetBuildVersion();
        string output = outputDirectory+"Mawful.app";
        Debug.Log("#### BUILDING TO " + output + " ####");
        var report = BuildPipeline.BuildPlayer(scenes, output, BuildTarget.StandaloneOSX, BuildOptions.Development);
        Debug.Log("#### BUILD " + output + " DONE ####");
        Debug.Log(report.summary);
    }

    [MenuItem("Mawful/BuildWindows")]
    static void BuildWindows() {
        //EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Standalone, BuildTarget.StandaloneWindows64);
        EditorUserBuildSettings.SetPlatformSettings("Standalone", "CopyPDBFiles", "true");
        //AddressableAssetSettings.CleanPlayerContent(AddressableAssetSettingsDefaultObject.Settings.ActivePlayerDataBuilder);
        AddressableAssetSettings.CleanPlayerContent();
        AddressableAssetSettings.BuildPlayerContent();
        GetBuildVersion();
        string output = outputDirectory+"Mawful.exe";
        Debug.Log("#### BUILDING TO " + output + " ####");
        var report = BuildPipeline.BuildPlayer(scenes, output, BuildTarget.StandaloneWindows64, BuildOptions.Development);
        Debug.Log("#### BUILD " + output + " DONE ####");
        Debug.Log(report.summary);
    }

    [MenuItem("Mawful/BuildWindows32")]
    static void BuildWindows32() {
        //EditorUserBuildSettings.SwitchActiveBuildTarget(BuildTargetGroup.Standalone, BuildTarget.StandaloneWindows);
        EditorUserBuildSettings.SetPlatformSettings("Standalone", "CopyPDBFiles", "true");
        //AddressableAssetSettings.CleanPlayerContent(AddressableAssetSettingsDefaultObject.Settings.ActivePlayerDataBuilder);
        AddressableAssetSettings.CleanPlayerContent();
        AddressableAssetSettings.BuildPlayerContent();
        GetBuildVersion();
        string output = outputDirectory+"Mawful.exe";
        Debug.Log("#### BUILDING TO " + output + " ####");
        var report = BuildPipeline.BuildPlayer(scenes, output, BuildTarget.StandaloneWindows, BuildOptions.Development);
        Debug.Log("#### BUILD " + output + " DONE ####");
        Debug.Log(report.summary);
    }

    // This doesn't really work-- I think.
    private static void GetBuildVersion() {
        string version = Environment.GetEnvironmentVariable("BUILD_NUMBER"); 
        string gitcommit = Environment.GetEnvironmentVariable("GIT_COMMIT"); 
        if (!String.IsNullOrEmpty(version) && !String.IsNullOrEmpty(gitcommit)) {
            PlayerSettings.bundleVersion = version + "_" + gitcommit;
        } else if (!String.IsNullOrEmpty(version)) {
            PlayerSettings.bundleVersion = version;
        }
    }
}

#endif
