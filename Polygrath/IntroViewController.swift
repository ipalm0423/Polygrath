//
//  IntroViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/12/11.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupView()
        self.setupPageView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func setupView() {
        //navi, background, button
        self.navigationController?.navigationBarHidden = true
        Singleton.sharedInstance.setupBackgroundGradientColor(self)
    }
    
    
//page view
    var introText = ["Subject Should Wear the iWatch", "Keep Finger on Screen", "Ready?"]
    var subText = ["Open the Polygraph App on iWatch and Follow the Instruction.", "Subject Should Keep Touching on iWatch Screen When Testing. \n" + "Avoid Screen Off to Get the Realtime Heart Rate.", "When You Are Ready \n" + "Press Start Button on Both Side"]
    var introImageName = ["iwatchIntro", "fingerprint", "heartLine"]
    var pageViewController: UIPageViewController!
    var pageControl = 0
    
    //set up page view controller
    func setupPageView() {
        /* Getting the page View controller */
        self.pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PageViewController") as! UIPageViewController
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        
        let pageContentViewController = self.viewControllerAtIndex(0)
        self.pageViewController.setViewControllers([pageContentViewController!], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        
        /* We are substracting 20 because we have a start bar button whose height is 20*/
        self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
        
        
        
        
    }
    
    //set up page view controller's delegate
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if var index = (viewController as! IntroPageViewController).pageIndex {
            
            if index == 2 {
                //final page
                return nil
            }
            //increment the index to get the viewController after the current index
            
            index = index + 1
            
            return self.viewControllerAtIndex(index)
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if var index = (viewController as! IntroPageViewController).pageIndex {
            
            //if the index is the end of the array, return nil since we dont want a view controller after the last one
            if index == 0 {
                return nil
            }
            //increment the index to get the viewController after the current index
            index = index - 1
            return self.viewControllerAtIndex(index)
        }
        return nil
    }
    
    func viewControllerAtIndex(index : Int) -> UIViewController? {
        
        let contentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("IntroPageView") as! IntroPageViewController
        contentViewController.titleText = self.introText[index]
        contentViewController.subTitleText = self.subText[index]
        contentViewController.imageName = self.introImageName[index]
        contentViewController.pageIndex = index
        return contentViewController
        
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
