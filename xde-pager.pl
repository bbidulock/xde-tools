#!/usr/bin/perl

# in case we get executed (not sourced) as a shell program
eval 'exec perl -S $0 ${1+"@"}'
    if $running_under_some_shell;


=head1 NAME

xde-pager - make pcmanfm page on scroll wheel for fluxbox

=head1 SYNOPSIS

xde-pager [OPTIONS]

=head1 DESCRIPTION

One problem associated with using pcmanfm with fluxbox is that fluxbox
keys specification OnDesktop does not apply to windows on the C<Desktop>
layer.  One would like to do:

 OnDesktop Mouse1 :HideMenus
 OnDesktop Mouse2 :WorkspaceMenu
 OnDesktop Mouse3 :RootMenu

 OnDesktop Mouse4 :NextWorkspace
 OnDesktop Mouse5 :PrevWorkspace

Problem is that pcmanfm does not propagate button press directly, but
proxies them itself to the root window.  It is not propagating scroll
wheel events.

=cut
