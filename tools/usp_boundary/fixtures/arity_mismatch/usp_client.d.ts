export class UspClient {
    subscribe(subscription_id: string, path: string, notification_type: number): Promise<any>;
}
