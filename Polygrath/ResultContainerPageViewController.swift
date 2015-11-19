//
//  ResultContainerPageViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/11/16.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import Foundation

class ResultContainerPageViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    
//page VC
    var pageViewController: UIPageViewController!
    var identifiers = ["ResultSummaryViewController", "RecordTableViewController"]
    var pageControl = 0
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupPageView()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        self.setupNotify()
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.removeNotify()
    }
    
    
//page View
    func setupPageView() {
        /* Getting the page View controller */
        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        let pageContentViewController = self.getViewControllerAtIndex(0)
        self.pageViewController.setViewControllers([pageContentViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        self.pageControl = 0
        //frame
        self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
    }
    
    
    func getViewControllerAtIndex(index : Int) -> UIViewController? {
        
        //first
        if index == 0 {
            let VC = self.storyboard?.instantiateViewControllerWithIdentifier("ResultSummaryViewController") as! ResultSummaryViewController
            //setup
            
            return VC
            
        }
        
        //second view controller
        if index == 1 {
            let VC = self.storyboard?.instantiateViewControllerWithIdentifier("RecordTableViewController") as! RecordTableViewController
            //setup
            
            return VC
        }
        
        //else
        return nil
    }

    //setup page view data source
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        //final page
        if let VC = viewController as? RecordTableViewController {
            return nil
        }
        //page1
        if let VC = viewController as? ResultSummaryViewController {
            
            //increment the index to get the viewController after the current index
            return self.getViewControllerAtIndex(1)
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let VC = viewController as? RecordTableViewController {
            
            //increment the index to get the viewController after the current index
            return self.getViewControllerAtIndex(0)
            
        }
        if let VC = viewController as? ResultSummaryViewController {
            return nil
        }
        
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        print("move page to ")
        if let identifier = pageViewController.viewControllers![0].restorationIdentifier {
            switch identifier {
                
            case "ResultSummaryViewController" :
                self.pageControl = 0
                NSNotificationCenter.defaultCenter().postNotificationName("reportButtonTouch", object: self)
                print(".0")
                
            case "RecordTableViewController" :
                self.pageControl = 1
                NSNotificationCenter.defaultCenter().postNotificationName("recordButtonTouch", object: nil)
                print(".1")
                
            default :
                print("unable to change page")
                return
            }
        }
    }
    
    
//notifycation + page move
    func setupNotify() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("pageMoveForward:"), name:"pageMoveForward", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("pageMoveBackward:"), name:"pageMoveBackward", object: nil)
    }
    
    func removeNotify() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "pageMoveForward", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "pageMoveBackward", object: nil)
        
    }
    
    func pageMoveForward(note: NSNotification) {
        print("move page from.\(self.pageControl)")
        //max page = 1
        if self.pageControl < 1 {
            if let pageContentViewController = self.getViewControllerAtIndex(self.pageControl + 1) {
                self.pageViewController.setViewControllers([pageContentViewController], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
                self.pageControl++
                return
            }
        }
    }
    
    func pageMoveBackward(note: NSNotification) {
        print("move page from.\(self.pageControl)")
        //min page = 0
        if self.pageControl > 0 {
            if let pageContentViewController = self.getViewControllerAtIndex(self.pageControl - 1) {
                self.pageViewController.setViewControllers([pageContentViewController], direction: UIPageViewControllerNavigationDirection.Reverse, animated: true, completion: nil)
                self.pageControl--
                return
            }
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
