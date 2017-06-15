//
//  PhotosCollectionViewCollectionViewController.m
//  Test project
//
//  Created by sxsasha on 4/19/17.
//  Copyright © 2017 sxsasha. All rights reserved.
//

#import "PhotosCollectionView.h"
#import "GreedoCollectionViewLayout.h"
#import "ImageCollectionCell.h"
#import "PaintingViewController.h"

@interface PhotosCollectionView () <UICollectionViewDelegate, UICollectionViewDataSource, GreedoCollectionViewLayoutDataSource>

@property (strong, nonatomic) NSArray <NSString*> *smallImagesNames;
@property (strong, nonatomic) NSArray <NSString*> *imagesNames;
@property (strong, nonatomic) NSMutableArray <UIImage*> *images;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) GreedoCollectionViewLayout *collectionViewSizeCalculator;

@end

@implementation PhotosCollectionView

static NSString * const reuseIdentifier = @"ImageCollectionCell";

#pragma mark - Main ovveriden methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initImagesArrays];
    [self initSizeCalc];
    [self setupFlowLayout];
    
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
}

- (void)initImagesArrays {
    self.smallImagesNames = @[@"startup-photos_small", @"peoples-photo_small", @"man-photo_small", @"girl-photo_small", @"child-children-girl-happy_small"];
    self.imagesNames = @[@"startup-photos", @"peoples-photo", @"man-photo", @"girl-photo", @"child-children-girl-happy"];
    
    self.images = [NSMutableArray array];
    for(NSString *imageName in self.smallImagesNames) {
        UIImage *image = [UIImage imageNamed:imageName];
        [self.images addObject:image];
    }
}

- (void)initSizeCalc {
    self.collectionViewSizeCalculator = [[GreedoCollectionViewLayout alloc] initWithCollectionView:self.collectionView];
    self.collectionViewSizeCalculator.dataSource = self;
    self.collectionViewSizeCalculator.rowMaximumHeight = CGRectGetHeight(self.collectionView.bounds) / 3;
    self.collectionViewSizeCalculator.fixedHeight = NO;
}

- (void)setupFlowLayout {
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.minimumLineSpacing = 0.f;
    flowLayout.minimumInteritemSpacing = 0.f;
    flowLayout.headerReferenceSize = CGSizeZero;
    flowLayout.footerReferenceSize = CGSizeZero;
    flowLayout.sectionInset = UIEdgeInsetsZero;
    [self.collectionView setCollectionViewLayout:flowLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - GreedoCollectionViewLayoutDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.collectionViewSizeCalculator sizeForPhotoAtIndexPath:indexPath];
}

- (CGSize)greedoCollectionViewLayout:(GreedoCollectionViewLayout *)layout originalImageSizeAtIndexPath:(NSIndexPath *)indexPath  {
    if (indexPath.item < self.images.count) {
        CGSize size = [self.images objectAtIndex:indexPath.row].size;
        return size;
    }

    return CGSizeMake(0.1, 0.1);
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ImageCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

    UIImage *image = [self.images objectAtIndex:indexPath.row];
    cell.imageView.image = image;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


#pragma mark - Copy menu Action

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    return action == NSSelectorFromString(@"copy:");
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender {
    if (action == @selector(copy:)) {
        UIImage *image = [self.images objectAtIndex:indexPath.row];
        [UIPasteboard generalPasteboard].image = image;
    }
}

#pragma mark - Select Action

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    NSString *imageName = [self.imagesNames objectAtIndex:indexPath.row];
    UIImage *image = [UIImage imageNamed:imageName];
    [self openImageFullScreen:image];
}

#pragma mark - Full Images Open

- (void)openImageFullScreen:(UIImage *)image {
    
    UIStoryboard *defaultStorybord = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    PaintingViewController *paintVC = [defaultStorybord instantiateViewControllerWithIdentifier:@"PaintingViewController"];
    paintVC.image = image;
    [self presentViewController:paintVC animated:YES completion:nil];
}
@end
