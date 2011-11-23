//
//  PullRefreshTableViewController.m
//  Plancast
//
//  Created by Leah Culver on 7/2/10.
//  Copyright (c) 2010 Leah Culver
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import <QuartzCore/QuartzCore.h>
#import "PullRefreshTableViewController.h"

#define REFRESH_HEADER_HEIGHT 52.0f

@interface PullRefreshTableViewController ()
- (void)startLoadingAnimated:(BOOL)animated fromDrag:(BOOL)dragged;
@end

@implementation PullRefreshTableViewController

@synthesize textPull, textRelease, textLoading, refreshHeaderView, refreshLabel, refreshArrow, refreshSpinner, appliesAlphaTransition, loading = isLoading, contentInset;

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (self != nil) {
    [self setupStrings];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self != nil) {
    [self setupStrings];
  }
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self != nil) {
    [self setupStrings];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self addPullToRefreshHeader];
}

- (void)setupStrings{
  textPull = [[NSString alloc] initWithString:@"Pull down to refresh..."];
  textRelease = [[NSString alloc] initWithString:@"Release to refresh..."];
  textLoading = [[NSString alloc] initWithString:@"Loading..."];
}

- (void)addPullToRefreshHeader {
    UITableView *tableView = self.tableView;
    CGFloat width = tableView.bounds.size.width;
    
    CGRect frame = CGRectMake(0, 0 - REFRESH_HEADER_HEIGHT, width, REFRESH_HEADER_HEIGHT);
    if (!refreshHeaderView)
        refreshHeaderView = [[UIView alloc] initWithFrame:frame];
    else
        refreshHeaderView.frame = frame;
    refreshHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    refreshHeaderView.backgroundColor = [UIColor clearColor];
    refreshHeaderView.alpha = appliesAlphaTransition ? 0.0f : 1.0f;

    frame = CGRectMake(0, 0, width, REFRESH_HEADER_HEIGHT);
    if (!refreshLabel)
        refreshLabel = [[UILabel alloc] initWithFrame:frame];
    else
        refreshLabel.frame = frame;
    refreshLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    refreshLabel.backgroundColor = [UIColor clearColor];
    refreshLabel.font = [UIFont boldSystemFontOfSize:12.0];
    refreshLabel.textAlignment = UITextAlignmentCenter;

    if (!refreshArrow)
        refreshArrow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow.png"]];
    refreshArrow.frame = CGRectMake(floorf((REFRESH_HEADER_HEIGHT - 27) / 2),
                                    (floorf(REFRESH_HEADER_HEIGHT - 44) / 2),
                                    27, 44);

    if (!refreshSpinner)
        refreshSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    refreshSpinner.frame = CGRectMake(floorf(floorf(REFRESH_HEADER_HEIGHT - 20) / 2), floorf((REFRESH_HEADER_HEIGHT - 20) / 2), 20, 20);
    refreshSpinner.hidesWhenStopped = NO;

    [refreshHeaderView addSubview:refreshLabel];
    [refreshHeaderView addSubview:refreshArrow];
    [refreshHeaderView addSubview:refreshSpinner];
    [tableView addSubview:refreshHeaderView];
    tableView.contentInset = contentInset;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (isLoading) return;
    isDragging = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    UIEdgeInsets insets = contentInset;
    if (isLoading) {
        refreshHeaderView.alpha = 1.0f;
        // Update the content inset, good for section headers
        if (scrollView.contentOffset.y > 0)
            self.tableView.contentInset = insets;
        else if (scrollView.contentOffset.y >= insets.top - REFRESH_HEADER_HEIGHT) {
            insets.top -= scrollView.contentOffset.y;
            self.tableView.contentInset = insets;
        }
    } else if (isDragging) {
        // Update the arrow direction and label
        CGFloat alpha = (scrollView.contentOffset.y + insets.top) * (-1.0f / REFRESH_HEADER_HEIGHT);
        if (alpha < 0.0f)
            alpha = 0.0f;
        else if (alpha > 1.0f)
            alpha = 1.0f;
        if (appliesAlphaTransition)
            refreshHeaderView.alpha = alpha;
        if (alpha >= 1.0f) {
            // User is scrolling above the header
            [UIView beginAnimations:nil context:NULL];
            refreshLabel.text = self.textRelease;
            [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI, 0, 0, 1);
            [UIView commitAnimations];
        } else { // User is scrolling somewhere within the header
            [UIView beginAnimations:nil context:NULL];
            refreshLabel.text = self.textPull;
            [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
            [UIView commitAnimations];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (isLoading) return;
    isDragging = NO;
    if (scrollView.contentOffset.y <= -REFRESH_HEADER_HEIGHT - contentInset.top) {
        // Released above the header
        [self startLoadingAnimated:YES fromDrag:YES];
        [self refresh];
    } else if (appliesAlphaTransition) {
        [UIView beginAnimations:nil context:NULL];
        refreshHeaderView.alpha = 0.0f;
        [UIView commitAnimations];
    }
}

- (void)startLoadingAnimated:(BOOL)animated fromDrag:(BOOL)dragged {
    if (isLoading)
        return;
    isLoading = YES;

    // Show the header
    if (appliesAlphaTransition && !dragged) {
        refreshArrow.alpha = 0.0f;
        refreshSpinner.alpha = 1.0f;
        refreshHeaderView.alpha = 1.0f;
    }
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.3];
    }
    if (!appliesAlphaTransition || dragged) {
        refreshArrow.alpha = 0.0f;
        refreshSpinner.alpha = 1.0f;
        refreshHeaderView.alpha = 1.0f;
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.removedOnCompletion = YES;
        [refreshLabel.layer addAnimation:transition forKey:@"contents"];
    }
    UIEdgeInsets insets = contentInset;
    insets.top += REFRESH_HEADER_HEIGHT;
    self.tableView.contentInset = insets;
    refreshLabel.text = self.textLoading;
    [refreshSpinner startAnimating];
    [self startedLoading];
    if (animated)
        [UIView commitAnimations];
}

- (void)startLoadingAnimated:(BOOL)animated
{
    [self startLoadingAnimated:animated fromDrag:NO];
}

- (void)startLoading
{
    [self startLoadingAnimated:YES];
}

- (void)stopLoadingAnimated:(BOOL)animated {
    if (!isLoading)
        return;
    isLoading = NO;

    // Hide the header
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDuration:0.3];
        [UIView setAnimationDidStopSelector:@selector(stopLoadingComplete:finished:context:)];
    }
    self.tableView.contentInset = contentInset;
    [refreshArrow layer].transform = CATransform3DMakeRotation(M_PI * 2, 0, 0, 1);
    if (appliesAlphaTransition)
        refreshHeaderView.alpha = 0.0f;
    if (!appliesAlphaTransition || !animated) {
        refreshLabel.text = self.textPull;
        refreshArrow.alpha = 1.0f;
        refreshSpinner.alpha = 0.0f;
        CATransition *transition = [CATransition animation];
        transition.duration = 0.3;
        transition.removedOnCompletion = YES;
        [refreshLabel.layer addAnimation:transition forKey:@"contents"];
    }
    [self stoppedLoading];
    if (animated)
        [UIView commitAnimations];
    else
        [refreshSpinner stopAnimating];
}

- (void)stopLoading
{
    [self stopLoadingAnimated:YES];
}

- (void)stopLoadingComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    // Reset the header
    refreshArrow.alpha = 1.0f;
    refreshSpinner.alpha = 0.0f;
    refreshLabel.text = self.textPull;
    [refreshSpinner stopAnimating];
}

- (void)refresh {
    // This is just a demo. Override this method with your custom reload action.
    // Don't forget to call stopLoading at the end.
    [self performSelector:@selector(stopLoading) withObject:nil afterDelay:2.0];
}

- (void)startedLoading
{
}

- (void)stoppedLoading
{
}

- (void)dealloc {
    [refreshHeaderView release];
    [refreshLabel release];
    [refreshArrow release];
    [refreshSpinner release];
    [textPull release];
    [textRelease release];
    [textLoading release];
    [super dealloc];
}

@end
