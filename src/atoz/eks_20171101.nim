
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elastic Kubernetes Service
## version: 2017-11-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p>Amazon Elastic Kubernetes Service (Amazon EKS) is a managed service that makes it easy for you to run Kubernetes on AWS without needing to stand up or maintain your own Kubernetes control plane. Kubernetes is an open-source system for automating the deployment, scaling, and management of containerized applications. </p> <p>Amazon EKS runs up-to-date versions of the open-source Kubernetes software, so you can use all the existing plugins and tooling from the Kubernetes community. Applications running on Amazon EKS are fully compatible with applications running on any standard Kubernetes environment, whether running in on-premises data centers or public clouds. This means that you can easily migrate any standard Kubernetes application to Amazon EKS without any code modification required.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/eks/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                       default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
                                                            ## a suitable default value when appropriate
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Https: {"ap-northeast-1": "eks.ap-northeast-1.amazonaws.com", "ap-southeast-1": "eks.ap-southeast-1.amazonaws.com",
                               "us-west-2": "eks.us-west-2.amazonaws.com",
                               "eu-west-2": "eks.eu-west-2.amazonaws.com", "ap-northeast-3": "eks.ap-northeast-3.amazonaws.com", "eu-central-1": "eks.eu-central-1.amazonaws.com",
                               "us-east-2": "eks.us-east-2.amazonaws.com",
                               "us-east-1": "eks.us-east-1.amazonaws.com", "cn-northwest-1": "eks.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "eks.ap-south-1.amazonaws.com",
                               "eu-north-1": "eks.eu-north-1.amazonaws.com", "ap-northeast-2": "eks.ap-northeast-2.amazonaws.com",
                               "us-west-1": "eks.us-west-1.amazonaws.com", "us-gov-east-1": "eks.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "eks.eu-west-3.amazonaws.com",
                               "cn-north-1": "eks.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "eks.sa-east-1.amazonaws.com",
                               "eu-west-1": "eks.eu-west-1.amazonaws.com", "us-gov-west-1": "eks.us-gov-west-1.amazonaws.com", "ap-southeast-2": "eks.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "eks.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "eks.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "eks.ap-southeast-1.amazonaws.com",
      "us-west-2": "eks.us-west-2.amazonaws.com",
      "eu-west-2": "eks.eu-west-2.amazonaws.com",
      "ap-northeast-3": "eks.ap-northeast-3.amazonaws.com",
      "eu-central-1": "eks.eu-central-1.amazonaws.com",
      "us-east-2": "eks.us-east-2.amazonaws.com",
      "us-east-1": "eks.us-east-1.amazonaws.com",
      "cn-northwest-1": "eks.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "eks.ap-south-1.amazonaws.com",
      "eu-north-1": "eks.eu-north-1.amazonaws.com",
      "ap-northeast-2": "eks.ap-northeast-2.amazonaws.com",
      "us-west-1": "eks.us-west-1.amazonaws.com",
      "us-gov-east-1": "eks.us-gov-east-1.amazonaws.com",
      "eu-west-3": "eks.eu-west-3.amazonaws.com",
      "cn-north-1": "eks.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "eks.sa-east-1.amazonaws.com",
      "eu-west-1": "eks.eu-west-1.amazonaws.com",
      "us-gov-west-1": "eks.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "eks.ap-southeast-2.amazonaws.com",
      "ca-central-1": "eks.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "eks"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateCluster_402656477 = ref object of OpenApiRestCall_402656044
proc url_CreateCluster_402656479(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_402656478(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656480 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-Security-Token", valid_402656480
  var valid_402656481 = header.getOrDefault("X-Amz-Signature")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Signature", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Algorithm", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Date")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Date", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Credential")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Credential", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656486
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656488: Call_CreateCluster_402656477; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656488.validator(path, query, header, formData, body, _)
  let scheme = call_402656488.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656488.makeUrl(scheme.get, call_402656488.host, call_402656488.base,
                                   call_402656488.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656488, uri, valid, _)

proc call*(call_402656489: Call_CreateCluster_402656477; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656490 = newJObject()
  if body != nil:
    body_402656490 = body
  result = call_402656489.call(nil, nil, nil, nil, body_402656490)

var createCluster* = Call_CreateCluster_402656477(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_CreateCluster_402656478, base: "/",
    makeUrl: url_CreateCluster_402656479, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_402656294 = ref object of OpenApiRestCall_402656044
proc url_ListClusters_402656296(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListClusters_402656295(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of cluster results returned by <code>ListClusters</code> in paginated output. When you use this parameter, <code>ListClusters</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListClusters</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListClusters</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## nextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <p>The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <code>ListClusters</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <code>maxResults</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## was 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## used 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## exceeded 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## parameter. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## continues 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## end 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## value.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <note> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## <p>This 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## should 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## be 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## treated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## as 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## an 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## opaque 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## identifier 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## used 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## only 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## retrieve 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## items 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## in 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## not 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## for 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## other 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## programmatic 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## purposes.</p> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## </note>
  section = newJObject()
  var valid_402656375 = query.getOrDefault("maxResults")
  valid_402656375 = validateParameter(valid_402656375, JInt, required = false,
                                      default = nil)
  if valid_402656375 != nil:
    section.add "maxResults", valid_402656375
  var valid_402656376 = query.getOrDefault("nextToken")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "nextToken", valid_402656376
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656377 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-Security-Token", valid_402656377
  var valid_402656378 = header.getOrDefault("X-Amz-Signature")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "X-Amz-Signature", valid_402656378
  var valid_402656379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Algorithm", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Date")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Date", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Credential")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Credential", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656397: Call_ListClusters_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
                                                                                         ## 
  let valid = call_402656397.validator(path, query, header, formData, body, _)
  let scheme = call_402656397.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656397.makeUrl(scheme.get, call_402656397.host, call_402656397.base,
                                   call_402656397.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656397, uri, valid, _)

proc call*(call_402656446: Call_ListClusters_402656294; maxResults: int = 0;
           nextToken: string = ""): Recallable =
  ## listClusters
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ##   
                                                                               ## maxResults: int
                                                                               ##             
                                                                               ## : 
                                                                               ## The 
                                                                               ## maximum 
                                                                               ## number 
                                                                               ## of 
                                                                               ## cluster 
                                                                               ## results 
                                                                               ## returned 
                                                                               ## by 
                                                                               ## <code>ListClusters</code> 
                                                                               ## in 
                                                                               ## paginated 
                                                                               ## output. 
                                                                               ## When 
                                                                               ## you 
                                                                               ## use 
                                                                               ## this 
                                                                               ## parameter, 
                                                                               ## <code>ListClusters</code> 
                                                                               ## returns 
                                                                               ## only 
                                                                               ## <code>maxResults</code> 
                                                                               ## results 
                                                                               ## in 
                                                                               ## a 
                                                                               ## single 
                                                                               ## page 
                                                                               ## along 
                                                                               ## with 
                                                                               ## a 
                                                                               ## <code>nextToken</code> 
                                                                               ## response 
                                                                               ## element. 
                                                                               ## You 
                                                                               ## can 
                                                                               ## see 
                                                                               ## the 
                                                                               ## remaining 
                                                                               ## results 
                                                                               ## of 
                                                                               ## the 
                                                                               ## initial 
                                                                               ## request 
                                                                               ## by 
                                                                               ## sending 
                                                                               ## another 
                                                                               ## <code>ListClusters</code> 
                                                                               ## request 
                                                                               ## with 
                                                                               ## the 
                                                                               ## returned 
                                                                               ## <code>nextToken</code> 
                                                                               ## value. 
                                                                               ## This 
                                                                               ## value 
                                                                               ## can 
                                                                               ## be 
                                                                               ## between 
                                                                               ## 1 
                                                                               ## and 
                                                                               ## 100. 
                                                                               ## If 
                                                                               ## you 
                                                                               ## don't 
                                                                               ## use 
                                                                               ## this 
                                                                               ## parameter, 
                                                                               ## <code>ListClusters</code> 
                                                                               ## returns 
                                                                               ## up 
                                                                               ## to 
                                                                               ## 100 
                                                                               ## results 
                                                                               ## and 
                                                                               ## a 
                                                                               ## <code>nextToken</code> 
                                                                               ## value 
                                                                               ## if 
                                                                               ## applicable.
  ##   
                                                                                             ## nextToken: string
                                                                                             ##            
                                                                                             ## : 
                                                                                             ## <p>The 
                                                                                             ## <code>nextToken</code> 
                                                                                             ## value 
                                                                                             ## returned 
                                                                                             ## from 
                                                                                             ## a 
                                                                                             ## previous 
                                                                                             ## paginated 
                                                                                             ## <code>ListClusters</code> 
                                                                                             ## request 
                                                                                             ## where 
                                                                                             ## <code>maxResults</code> 
                                                                                             ## was 
                                                                                             ## used 
                                                                                             ## and 
                                                                                             ## the 
                                                                                             ## results 
                                                                                             ## exceeded 
                                                                                             ## the 
                                                                                             ## value 
                                                                                             ## of 
                                                                                             ## that 
                                                                                             ## parameter. 
                                                                                             ## Pagination 
                                                                                             ## continues 
                                                                                             ## from 
                                                                                             ## the 
                                                                                             ## end 
                                                                                             ## of 
                                                                                             ## the 
                                                                                             ## previous 
                                                                                             ## results 
                                                                                             ## that 
                                                                                             ## returned 
                                                                                             ## the 
                                                                                             ## <code>nextToken</code> 
                                                                                             ## value.</p> 
                                                                                             ## <note> 
                                                                                             ## <p>This 
                                                                                             ## token 
                                                                                             ## should 
                                                                                             ## be 
                                                                                             ## treated 
                                                                                             ## as 
                                                                                             ## an 
                                                                                             ## opaque 
                                                                                             ## identifier 
                                                                                             ## that 
                                                                                             ## is 
                                                                                             ## used 
                                                                                             ## only 
                                                                                             ## to 
                                                                                             ## retrieve 
                                                                                             ## the 
                                                                                             ## next 
                                                                                             ## items 
                                                                                             ## in 
                                                                                             ## a 
                                                                                             ## list 
                                                                                             ## and 
                                                                                             ## not 
                                                                                             ## for 
                                                                                             ## other 
                                                                                             ## programmatic 
                                                                                             ## purposes.</p> 
                                                                                             ## </note>
  var query_402656447 = newJObject()
  add(query_402656447, "maxResults", newJInt(maxResults))
  add(query_402656447, "nextToken", newJString(nextToken))
  result = call_402656446.call(nil, query_402656447, nil, nil, nil)

var listClusters* = Call_ListClusters_402656294(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_ListClusters_402656295, base: "/",
    makeUrl: url_ListClusters_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFargateProfile_402656519 = ref object of OpenApiRestCall_402656044
proc url_CreateFargateProfile_402656521(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/fargate-profiles")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFargateProfile_402656520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster to apply the Fargate profile to.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656522 = path.getOrDefault("name")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true,
                                      default = nil)
  if valid_402656522 != nil:
    section.add "name", valid_402656522
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_CreateFargateProfile_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_CreateFargateProfile_402656519; name: string;
           body: JsonNode): Recallable =
  ## createFargateProfile
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## EKS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## cluster 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## apply 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Fargate 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## profile 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## to.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var path_402656533 = newJObject()
  var body_402656534 = newJObject()
  add(path_402656533, "name", newJString(name))
  if body != nil:
    body_402656534 = body
  result = call_402656532.call(path_402656533, nil, nil, nil, body_402656534)

var createFargateProfile* = Call_CreateFargateProfile_402656519(
    name: "createFargateProfile", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_CreateFargateProfile_402656520, base: "/",
    makeUrl: url_CreateFargateProfile_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFargateProfiles_402656491 = ref object of OpenApiRestCall_402656044
proc url_ListFargateProfiles_402656493(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/fargate-profiles")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFargateProfiles_402656492(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster that you would like to listFargate profiles in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656505 = path.getOrDefault("name")
  valid_402656505 = validateParameter(valid_402656505, JString, required = true,
                                      default = nil)
  if valid_402656505 != nil:
    section.add "name", valid_402656505
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of Fargate profile results returned by <code>ListFargateProfiles</code> in paginated output. When you use this parameter, <code>ListFargateProfiles</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListFargateProfiles</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListFargateProfiles</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## nextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## <code>ListFargateProfiles</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## <code>maxResults</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## was 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## used 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## exceeded 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## parameter. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## continues 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## end 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## value.
  section = newJObject()
  var valid_402656506 = query.getOrDefault("maxResults")
  valid_402656506 = validateParameter(valid_402656506, JInt, required = false,
                                      default = nil)
  if valid_402656506 != nil:
    section.add "maxResults", valid_402656506
  var valid_402656507 = query.getOrDefault("nextToken")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "nextToken", valid_402656507
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656515: Call_ListFargateProfiles_402656491;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
                                                                                         ## 
  let valid = call_402656515.validator(path, query, header, formData, body, _)
  let scheme = call_402656515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656515.makeUrl(scheme.get, call_402656515.host, call_402656515.base,
                                   call_402656515.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656515, uri, valid, _)

proc call*(call_402656516: Call_ListFargateProfiles_402656491; name: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listFargateProfiles
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ##   
                                                                                                                      ## maxResults: int
                                                                                                                      ##             
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## maximum 
                                                                                                                      ## number 
                                                                                                                      ## of 
                                                                                                                      ## Fargate 
                                                                                                                      ## profile 
                                                                                                                      ## results 
                                                                                                                      ## returned 
                                                                                                                      ## by 
                                                                                                                      ## <code>ListFargateProfiles</code> 
                                                                                                                      ## in 
                                                                                                                      ## paginated 
                                                                                                                      ## output. 
                                                                                                                      ## When 
                                                                                                                      ## you 
                                                                                                                      ## use 
                                                                                                                      ## this 
                                                                                                                      ## parameter, 
                                                                                                                      ## <code>ListFargateProfiles</code> 
                                                                                                                      ## returns 
                                                                                                                      ## only 
                                                                                                                      ## <code>maxResults</code> 
                                                                                                                      ## results 
                                                                                                                      ## in 
                                                                                                                      ## a 
                                                                                                                      ## single 
                                                                                                                      ## page 
                                                                                                                      ## along 
                                                                                                                      ## with 
                                                                                                                      ## a 
                                                                                                                      ## <code>nextToken</code> 
                                                                                                                      ## response 
                                                                                                                      ## element. 
                                                                                                                      ## You 
                                                                                                                      ## can 
                                                                                                                      ## see 
                                                                                                                      ## the 
                                                                                                                      ## remaining 
                                                                                                                      ## results 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## initial 
                                                                                                                      ## request 
                                                                                                                      ## by 
                                                                                                                      ## sending 
                                                                                                                      ## another 
                                                                                                                      ## <code>ListFargateProfiles</code> 
                                                                                                                      ## request 
                                                                                                                      ## with 
                                                                                                                      ## the 
                                                                                                                      ## returned 
                                                                                                                      ## <code>nextToken</code> 
                                                                                                                      ## value. 
                                                                                                                      ## This 
                                                                                                                      ## value 
                                                                                                                      ## can 
                                                                                                                      ## be 
                                                                                                                      ## between 
                                                                                                                      ## 1 
                                                                                                                      ## and 
                                                                                                                      ## 100. 
                                                                                                                      ## If 
                                                                                                                      ## you 
                                                                                                                      ## don't 
                                                                                                                      ## use 
                                                                                                                      ## this 
                                                                                                                      ## parameter, 
                                                                                                                      ## <code>ListFargateProfiles</code> 
                                                                                                                      ## returns 
                                                                                                                      ## up 
                                                                                                                      ## to 
                                                                                                                      ## 100 
                                                                                                                      ## results 
                                                                                                                      ## and 
                                                                                                                      ## a 
                                                                                                                      ## <code>nextToken</code> 
                                                                                                                      ## value 
                                                                                                                      ## if 
                                                                                                                      ## applicable.
  ##   
                                                                                                                                    ## name: string (required)
                                                                                                                                    ##       
                                                                                                                                    ## : 
                                                                                                                                    ## The 
                                                                                                                                    ## name 
                                                                                                                                    ## of 
                                                                                                                                    ## the 
                                                                                                                                    ## Amazon 
                                                                                                                                    ## EKS 
                                                                                                                                    ## cluster 
                                                                                                                                    ## that 
                                                                                                                                    ## you 
                                                                                                                                    ## would 
                                                                                                                                    ## like 
                                                                                                                                    ## to 
                                                                                                                                    ## listFargate 
                                                                                                                                    ## profiles 
                                                                                                                                    ## in.
  ##   
                                                                                                                                          ## nextToken: string
                                                                                                                                          ##            
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## <code>nextToken</code> 
                                                                                                                                          ## value 
                                                                                                                                          ## returned 
                                                                                                                                          ## from 
                                                                                                                                          ## a 
                                                                                                                                          ## previous 
                                                                                                                                          ## paginated 
                                                                                                                                          ## <code>ListFargateProfiles</code> 
                                                                                                                                          ## request 
                                                                                                                                          ## where 
                                                                                                                                          ## <code>maxResults</code> 
                                                                                                                                          ## was 
                                                                                                                                          ## used 
                                                                                                                                          ## and 
                                                                                                                                          ## the 
                                                                                                                                          ## results 
                                                                                                                                          ## exceeded 
                                                                                                                                          ## the 
                                                                                                                                          ## value 
                                                                                                                                          ## of 
                                                                                                                                          ## that 
                                                                                                                                          ## parameter. 
                                                                                                                                          ## Pagination 
                                                                                                                                          ## continues 
                                                                                                                                          ## from 
                                                                                                                                          ## the 
                                                                                                                                          ## end 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## previous 
                                                                                                                                          ## results 
                                                                                                                                          ## that 
                                                                                                                                          ## returned 
                                                                                                                                          ## the 
                                                                                                                                          ## <code>nextToken</code> 
                                                                                                                                          ## value.
  var path_402656517 = newJObject()
  var query_402656518 = newJObject()
  add(query_402656518, "maxResults", newJInt(maxResults))
  add(path_402656517, "name", newJString(name))
  add(query_402656518, "nextToken", newJString(nextToken))
  result = call_402656516.call(path_402656517, query_402656518, nil, nil, nil)

var listFargateProfiles* = Call_ListFargateProfiles_402656491(
    name: "listFargateProfiles", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_ListFargateProfiles_402656492, base: "/",
    makeUrl: url_ListFargateProfiles_402656493,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNodegroup_402656552 = ref object of OpenApiRestCall_402656044
proc url_CreateNodegroup_402656554(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/node-groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateNodegroup_402656553(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the cluster to create the node group in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656555 = path.getOrDefault("name")
  valid_402656555 = validateParameter(valid_402656555, JString, required = true,
                                      default = nil)
  if valid_402656555 != nil:
    section.add "name", valid_402656555
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656556 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Security-Token", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Signature")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Signature", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-Algorithm", valid_402656559
  var valid_402656560 = header.getOrDefault("X-Amz-Date")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Date", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Credential")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Credential", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656562
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656564: Call_CreateNodegroup_402656552; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
                                                                                         ## 
  let valid = call_402656564.validator(path, query, header, formData, body, _)
  let scheme = call_402656564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656564.makeUrl(scheme.get, call_402656564.host, call_402656564.base,
                                   call_402656564.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656564, uri, valid, _)

proc call*(call_402656565: Call_CreateNodegroup_402656552; name: string;
           body: JsonNode): Recallable =
  ## createNodegroup
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## cluster 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## create 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## node 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## group 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## in.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var path_402656566 = newJObject()
  var body_402656567 = newJObject()
  add(path_402656566, "name", newJString(name))
  if body != nil:
    body_402656567 = body
  result = call_402656565.call(path_402656566, nil, nil, nil, body_402656567)

var createNodegroup* = Call_CreateNodegroup_402656552(name: "createNodegroup",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_CreateNodegroup_402656553,
    base: "/", makeUrl: url_CreateNodegroup_402656554,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodegroups_402656535 = ref object of OpenApiRestCall_402656044
proc url_ListNodegroups_402656537(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/node-groups")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListNodegroups_402656536(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster that you would like to list node groups in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656538 = path.getOrDefault("name")
  valid_402656538 = validateParameter(valid_402656538, JString, required = true,
                                      default = nil)
  if valid_402656538 != nil:
    section.add "name", valid_402656538
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## nextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## <code>ListNodegroups</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## <code>maxResults</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## was 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## used 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## exceeded 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## parameter. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## continues 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## end 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## value.
  section = newJObject()
  var valid_402656539 = query.getOrDefault("maxResults")
  valid_402656539 = validateParameter(valid_402656539, JInt, required = false,
                                      default = nil)
  if valid_402656539 != nil:
    section.add "maxResults", valid_402656539
  var valid_402656540 = query.getOrDefault("nextToken")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "nextToken", valid_402656540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656541 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Security-Token", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Signature")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Signature", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Algorithm", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Date")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Date", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Credential")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Credential", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656548: Call_ListNodegroups_402656535; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
                                                                                         ## 
  let valid = call_402656548.validator(path, query, header, formData, body, _)
  let scheme = call_402656548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656548.makeUrl(scheme.get, call_402656548.host, call_402656548.base,
                                   call_402656548.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656548, uri, valid, _)

proc call*(call_402656549: Call_ListNodegroups_402656535; name: string;
           maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listNodegroups
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ##   
                                                                                                                        ## maxResults: int
                                                                                                                        ##             
                                                                                                                        ## : 
                                                                                                                        ## The 
                                                                                                                        ## maximum 
                                                                                                                        ## number 
                                                                                                                        ## of 
                                                                                                                        ## node 
                                                                                                                        ## group 
                                                                                                                        ## results 
                                                                                                                        ## returned 
                                                                                                                        ## by 
                                                                                                                        ## <code>ListNodegroups</code> 
                                                                                                                        ## in 
                                                                                                                        ## paginated 
                                                                                                                        ## output. 
                                                                                                                        ## When 
                                                                                                                        ## you 
                                                                                                                        ## use 
                                                                                                                        ## this 
                                                                                                                        ## parameter, 
                                                                                                                        ## <code>ListNodegroups</code> 
                                                                                                                        ## returns 
                                                                                                                        ## only 
                                                                                                                        ## <code>maxResults</code> 
                                                                                                                        ## results 
                                                                                                                        ## in 
                                                                                                                        ## a 
                                                                                                                        ## single 
                                                                                                                        ## page 
                                                                                                                        ## along 
                                                                                                                        ## with 
                                                                                                                        ## a 
                                                                                                                        ## <code>nextToken</code> 
                                                                                                                        ## response 
                                                                                                                        ## element. 
                                                                                                                        ## You 
                                                                                                                        ## can 
                                                                                                                        ## see 
                                                                                                                        ## the 
                                                                                                                        ## remaining 
                                                                                                                        ## results 
                                                                                                                        ## of 
                                                                                                                        ## the 
                                                                                                                        ## initial 
                                                                                                                        ## request 
                                                                                                                        ## by 
                                                                                                                        ## sending 
                                                                                                                        ## another 
                                                                                                                        ## <code>ListNodegroups</code> 
                                                                                                                        ## request 
                                                                                                                        ## with 
                                                                                                                        ## the 
                                                                                                                        ## returned 
                                                                                                                        ## <code>nextToken</code> 
                                                                                                                        ## value. 
                                                                                                                        ## This 
                                                                                                                        ## value 
                                                                                                                        ## can 
                                                                                                                        ## be 
                                                                                                                        ## between 
                                                                                                                        ## 1 
                                                                                                                        ## and 
                                                                                                                        ## 100. 
                                                                                                                        ## If 
                                                                                                                        ## you 
                                                                                                                        ## don't 
                                                                                                                        ## use 
                                                                                                                        ## this 
                                                                                                                        ## parameter, 
                                                                                                                        ## <code>ListNodegroups</code> 
                                                                                                                        ## returns 
                                                                                                                        ## up 
                                                                                                                        ## to 
                                                                                                                        ## 100 
                                                                                                                        ## results 
                                                                                                                        ## and 
                                                                                                                        ## a 
                                                                                                                        ## <code>nextToken</code> 
                                                                                                                        ## value 
                                                                                                                        ## if 
                                                                                                                        ## applicable.
  ##   
                                                                                                                                      ## name: string (required)
                                                                                                                                      ##       
                                                                                                                                      ## : 
                                                                                                                                      ## The 
                                                                                                                                      ## name 
                                                                                                                                      ## of 
                                                                                                                                      ## the 
                                                                                                                                      ## Amazon 
                                                                                                                                      ## EKS 
                                                                                                                                      ## cluster 
                                                                                                                                      ## that 
                                                                                                                                      ## you 
                                                                                                                                      ## would 
                                                                                                                                      ## like 
                                                                                                                                      ## to 
                                                                                                                                      ## list 
                                                                                                                                      ## node 
                                                                                                                                      ## groups 
                                                                                                                                      ## in.
  ##   
                                                                                                                                            ## nextToken: string
                                                                                                                                            ##            
                                                                                                                                            ## : 
                                                                                                                                            ## The 
                                                                                                                                            ## <code>nextToken</code> 
                                                                                                                                            ## value 
                                                                                                                                            ## returned 
                                                                                                                                            ## from 
                                                                                                                                            ## a 
                                                                                                                                            ## previous 
                                                                                                                                            ## paginated 
                                                                                                                                            ## <code>ListNodegroups</code> 
                                                                                                                                            ## request 
                                                                                                                                            ## where 
                                                                                                                                            ## <code>maxResults</code> 
                                                                                                                                            ## was 
                                                                                                                                            ## used 
                                                                                                                                            ## and 
                                                                                                                                            ## the 
                                                                                                                                            ## results 
                                                                                                                                            ## exceeded 
                                                                                                                                            ## the 
                                                                                                                                            ## value 
                                                                                                                                            ## of 
                                                                                                                                            ## that 
                                                                                                                                            ## parameter. 
                                                                                                                                            ## Pagination 
                                                                                                                                            ## continues 
                                                                                                                                            ## from 
                                                                                                                                            ## the 
                                                                                                                                            ## end 
                                                                                                                                            ## of 
                                                                                                                                            ## the 
                                                                                                                                            ## previous 
                                                                                                                                            ## results 
                                                                                                                                            ## that 
                                                                                                                                            ## returned 
                                                                                                                                            ## the 
                                                                                                                                            ## <code>nextToken</code> 
                                                                                                                                            ## value.
  var path_402656550 = newJObject()
  var query_402656551 = newJObject()
  add(query_402656551, "maxResults", newJInt(maxResults))
  add(path_402656550, "name", newJString(name))
  add(query_402656551, "nextToken", newJString(nextToken))
  result = call_402656549.call(path_402656550, query_402656551, nil, nil, nil)

var listNodegroups* = Call_ListNodegroups_402656535(name: "listNodegroups",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_ListNodegroups_402656536,
    base: "/", makeUrl: url_ListNodegroups_402656537,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_402656568 = ref object of OpenApiRestCall_402656044
proc url_DescribeCluster_402656570(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeCluster_402656569(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the cluster to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656571 = path.getOrDefault("name")
  valid_402656571 = validateParameter(valid_402656571, JString, required = true,
                                      default = nil)
  if valid_402656571 != nil:
    section.add "name", valid_402656571
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656572 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Security-Token", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Signature")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Signature", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656574
  var valid_402656575 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656575 = validateParameter(valid_402656575, JString,
                                      required = false, default = nil)
  if valid_402656575 != nil:
    section.add "X-Amz-Algorithm", valid_402656575
  var valid_402656576 = header.getOrDefault("X-Amz-Date")
  valid_402656576 = validateParameter(valid_402656576, JString,
                                      required = false, default = nil)
  if valid_402656576 != nil:
    section.add "X-Amz-Date", valid_402656576
  var valid_402656577 = header.getOrDefault("X-Amz-Credential")
  valid_402656577 = validateParameter(valid_402656577, JString,
                                      required = false, default = nil)
  if valid_402656577 != nil:
    section.add "X-Amz-Credential", valid_402656577
  var valid_402656578 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656578 = validateParameter(valid_402656578, JString,
                                      required = false, default = nil)
  if valid_402656578 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656578
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656579: Call_DescribeCluster_402656568; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
                                                                                         ## 
  let valid = call_402656579.validator(path, query, header, formData, body, _)
  let scheme = call_402656579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656579.makeUrl(scheme.get, call_402656579.host, call_402656579.base,
                                   call_402656579.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656579, uri, valid, _)

proc call*(call_402656580: Call_DescribeCluster_402656568; name: string): Recallable =
  ## describeCluster
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## cluster 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## describe.
  var path_402656581 = newJObject()
  add(path_402656581, "name", newJString(name))
  result = call_402656580.call(path_402656581, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_402656568(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}", validator: validate_DescribeCluster_402656569,
    base: "/", makeUrl: url_DescribeCluster_402656570,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_402656582 = ref object of OpenApiRestCall_402656044
proc url_DeleteCluster_402656584(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCluster_402656583(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the cluster to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656585 = path.getOrDefault("name")
  valid_402656585 = validateParameter(valid_402656585, JString, required = true,
                                      default = nil)
  if valid_402656585 != nil:
    section.add "name", valid_402656585
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656586 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Security-Token", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Signature")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Signature", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-Algorithm", valid_402656589
  var valid_402656590 = header.getOrDefault("X-Amz-Date")
  valid_402656590 = validateParameter(valid_402656590, JString,
                                      required = false, default = nil)
  if valid_402656590 != nil:
    section.add "X-Amz-Date", valid_402656590
  var valid_402656591 = header.getOrDefault("X-Amz-Credential")
  valid_402656591 = validateParameter(valid_402656591, JString,
                                      required = false, default = nil)
  if valid_402656591 != nil:
    section.add "X-Amz-Credential", valid_402656591
  var valid_402656592 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656592 = validateParameter(valid_402656592, JString,
                                      required = false, default = nil)
  if valid_402656592 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656592
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656593: Call_DeleteCluster_402656582; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
                                                                                         ## 
  let valid = call_402656593.validator(path, query, header, formData, body, _)
  let scheme = call_402656593.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656593.makeUrl(scheme.get, call_402656593.host, call_402656593.base,
                                   call_402656593.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656593, uri, valid, _)

proc call*(call_402656594: Call_DeleteCluster_402656582; name: string): Recallable =
  ## deleteCluster
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## cluster 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## delete.
  var path_402656595 = newJObject()
  add(path_402656595, "name", newJString(name))
  result = call_402656594.call(path_402656595, nil, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_402656582(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}", validator: validate_DeleteCluster_402656583,
    base: "/", makeUrl: url_DeleteCluster_402656584,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFargateProfile_402656596 = ref object of OpenApiRestCall_402656044
proc url_DescribeFargateProfile_402656598(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "fargateProfileName" in path,
         "`fargateProfileName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/fargate-profiles/"),
                 (kind: VariableSegment, value: "fargateProfileName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeFargateProfile_402656597(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns descriptive information about an AWS Fargate profile.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster associated with the Fargate profile.
  ##   
                                                                                                                   ## fargateProfileName: JString (required)
                                                                                                                   ##                     
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## name 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## Fargate 
                                                                                                                   ## profile 
                                                                                                                   ## to 
                                                                                                                   ## describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656599 = path.getOrDefault("name")
  valid_402656599 = validateParameter(valid_402656599, JString, required = true,
                                      default = nil)
  if valid_402656599 != nil:
    section.add "name", valid_402656599
  var valid_402656600 = path.getOrDefault("fargateProfileName")
  valid_402656600 = validateParameter(valid_402656600, JString, required = true,
                                      default = nil)
  if valid_402656600 != nil:
    section.add "fargateProfileName", valid_402656600
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656601 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Security-Token", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Signature")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Signature", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-Algorithm", valid_402656604
  var valid_402656605 = header.getOrDefault("X-Amz-Date")
  valid_402656605 = validateParameter(valid_402656605, JString,
                                      required = false, default = nil)
  if valid_402656605 != nil:
    section.add "X-Amz-Date", valid_402656605
  var valid_402656606 = header.getOrDefault("X-Amz-Credential")
  valid_402656606 = validateParameter(valid_402656606, JString,
                                      required = false, default = nil)
  if valid_402656606 != nil:
    section.add "X-Amz-Credential", valid_402656606
  var valid_402656607 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656607 = validateParameter(valid_402656607, JString,
                                      required = false, default = nil)
  if valid_402656607 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656607
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656608: Call_DescribeFargateProfile_402656596;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns descriptive information about an AWS Fargate profile.
                                                                                         ## 
  let valid = call_402656608.validator(path, query, header, formData, body, _)
  let scheme = call_402656608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656608.makeUrl(scheme.get, call_402656608.host, call_402656608.base,
                                   call_402656608.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656608, uri, valid, _)

proc call*(call_402656609: Call_DescribeFargateProfile_402656596; name: string;
           fargateProfileName: string): Recallable =
  ## describeFargateProfile
  ## Returns descriptive information about an AWS Fargate profile.
  ##   name: string (required)
                                                                  ##       : The name of the Amazon EKS cluster associated with the Fargate profile.
  ##   
                                                                                                                                                    ## fargateProfileName: string (required)
                                                                                                                                                    ##                     
                                                                                                                                                    ## : 
                                                                                                                                                    ## The 
                                                                                                                                                    ## name 
                                                                                                                                                    ## of 
                                                                                                                                                    ## the 
                                                                                                                                                    ## Fargate 
                                                                                                                                                    ## profile 
                                                                                                                                                    ## to 
                                                                                                                                                    ## describe.
  var path_402656610 = newJObject()
  add(path_402656610, "name", newJString(name))
  add(path_402656610, "fargateProfileName", newJString(fargateProfileName))
  result = call_402656609.call(path_402656610, nil, nil, nil, nil)

var describeFargateProfile* = Call_DescribeFargateProfile_402656596(
    name: "describeFargateProfile", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DescribeFargateProfile_402656597, base: "/",
    makeUrl: url_DescribeFargateProfile_402656598,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFargateProfile_402656611 = ref object of OpenApiRestCall_402656044
proc url_DeleteFargateProfile_402656613(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "fargateProfileName" in path,
         "`fargateProfileName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/fargate-profiles/"),
                 (kind: VariableSegment, value: "fargateProfileName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFargateProfile_402656612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster associated with the Fargate profile to delete.
  ##   
                                                                                                                             ## fargateProfileName: JString (required)
                                                                                                                             ##                     
                                                                                                                             ## : 
                                                                                                                             ## The 
                                                                                                                             ## name 
                                                                                                                             ## of 
                                                                                                                             ## the 
                                                                                                                             ## Fargate 
                                                                                                                             ## profile 
                                                                                                                             ## to 
                                                                                                                             ## delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656614 = path.getOrDefault("name")
  valid_402656614 = validateParameter(valid_402656614, JString, required = true,
                                      default = nil)
  if valid_402656614 != nil:
    section.add "name", valid_402656614
  var valid_402656615 = path.getOrDefault("fargateProfileName")
  valid_402656615 = validateParameter(valid_402656615, JString, required = true,
                                      default = nil)
  if valid_402656615 != nil:
    section.add "fargateProfileName", valid_402656615
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656616 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Security-Token", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Signature")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Signature", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-Algorithm", valid_402656619
  var valid_402656620 = header.getOrDefault("X-Amz-Date")
  valid_402656620 = validateParameter(valid_402656620, JString,
                                      required = false, default = nil)
  if valid_402656620 != nil:
    section.add "X-Amz-Date", valid_402656620
  var valid_402656621 = header.getOrDefault("X-Amz-Credential")
  valid_402656621 = validateParameter(valid_402656621, JString,
                                      required = false, default = nil)
  if valid_402656621 != nil:
    section.add "X-Amz-Credential", valid_402656621
  var valid_402656622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656622 = validateParameter(valid_402656622, JString,
                                      required = false, default = nil)
  if valid_402656622 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656622
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656623: Call_DeleteFargateProfile_402656611;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
                                                                                         ## 
  let valid = call_402656623.validator(path, query, header, formData, body, _)
  let scheme = call_402656623.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656623.makeUrl(scheme.get, call_402656623.host, call_402656623.base,
                                   call_402656623.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656623, uri, valid, _)

proc call*(call_402656624: Call_DeleteFargateProfile_402656611; name: string;
           fargateProfileName: string): Recallable =
  ## deleteFargateProfile
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## EKS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## cluster 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## associated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Fargate 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## profile 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## delete.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## fargateProfileName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##                     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Fargate 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## profile 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## delete.
  var path_402656625 = newJObject()
  add(path_402656625, "name", newJString(name))
  add(path_402656625, "fargateProfileName", newJString(fargateProfileName))
  result = call_402656624.call(path_402656625, nil, nil, nil, nil)

var deleteFargateProfile* = Call_DeleteFargateProfile_402656611(
    name: "deleteFargateProfile", meth: HttpMethod.HttpDelete,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DeleteFargateProfile_402656612, base: "/",
    makeUrl: url_DeleteFargateProfile_402656613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodegroup_402656626 = ref object of OpenApiRestCall_402656044
proc url_DescribeNodegroup_402656628(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "nodegroupName" in path, "`nodegroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/node-groups/"),
                 (kind: VariableSegment, value: "nodegroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeNodegroup_402656627(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns descriptive information about an Amazon EKS node group.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster associated with the node group.
  ##   
                                                                                                              ## nodegroupName: JString (required)
                                                                                                              ##                
                                                                                                              ## : 
                                                                                                              ## The 
                                                                                                              ## name 
                                                                                                              ## of 
                                                                                                              ## the 
                                                                                                              ## node 
                                                                                                              ## group 
                                                                                                              ## to 
                                                                                                              ## describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656629 = path.getOrDefault("name")
  valid_402656629 = validateParameter(valid_402656629, JString, required = true,
                                      default = nil)
  if valid_402656629 != nil:
    section.add "name", valid_402656629
  var valid_402656630 = path.getOrDefault("nodegroupName")
  valid_402656630 = validateParameter(valid_402656630, JString, required = true,
                                      default = nil)
  if valid_402656630 != nil:
    section.add "nodegroupName", valid_402656630
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656631 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Security-Token", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Signature")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Signature", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-Algorithm", valid_402656634
  var valid_402656635 = header.getOrDefault("X-Amz-Date")
  valid_402656635 = validateParameter(valid_402656635, JString,
                                      required = false, default = nil)
  if valid_402656635 != nil:
    section.add "X-Amz-Date", valid_402656635
  var valid_402656636 = header.getOrDefault("X-Amz-Credential")
  valid_402656636 = validateParameter(valid_402656636, JString,
                                      required = false, default = nil)
  if valid_402656636 != nil:
    section.add "X-Amz-Credential", valid_402656636
  var valid_402656637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656637 = validateParameter(valid_402656637, JString,
                                      required = false, default = nil)
  if valid_402656637 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656637
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656638: Call_DescribeNodegroup_402656626;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns descriptive information about an Amazon EKS node group.
                                                                                         ## 
  let valid = call_402656638.validator(path, query, header, formData, body, _)
  let scheme = call_402656638.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656638.makeUrl(scheme.get, call_402656638.host, call_402656638.base,
                                   call_402656638.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656638, uri, valid, _)

proc call*(call_402656639: Call_DescribeNodegroup_402656626; name: string;
           nodegroupName: string): Recallable =
  ## describeNodegroup
  ## Returns descriptive information about an Amazon EKS node group.
  ##   name: string (required)
                                                                    ##       : The name of the Amazon EKS cluster associated with the node group.
  ##   
                                                                                                                                                 ## nodegroupName: string (required)
                                                                                                                                                 ##                
                                                                                                                                                 ## : 
                                                                                                                                                 ## The 
                                                                                                                                                 ## name 
                                                                                                                                                 ## of 
                                                                                                                                                 ## the 
                                                                                                                                                 ## node 
                                                                                                                                                 ## group 
                                                                                                                                                 ## to 
                                                                                                                                                 ## describe.
  var path_402656640 = newJObject()
  add(path_402656640, "name", newJString(name))
  add(path_402656640, "nodegroupName", newJString(nodegroupName))
  result = call_402656639.call(path_402656640, nil, nil, nil, nil)

var describeNodegroup* = Call_DescribeNodegroup_402656626(
    name: "describeNodegroup", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DescribeNodegroup_402656627, base: "/",
    makeUrl: url_DescribeNodegroup_402656628,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNodegroup_402656641 = ref object of OpenApiRestCall_402656044
proc url_DeleteNodegroup_402656643(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "nodegroupName" in path, "`nodegroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/node-groups/"),
                 (kind: VariableSegment, value: "nodegroupName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteNodegroup_402656642(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an Amazon EKS node group for a cluster.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster that is associated with your node group.
  ##   
                                                                                                                       ## nodegroupName: JString (required)
                                                                                                                       ##                
                                                                                                                       ## : 
                                                                                                                       ## The 
                                                                                                                       ## name 
                                                                                                                       ## of 
                                                                                                                       ## the 
                                                                                                                       ## node 
                                                                                                                       ## group 
                                                                                                                       ## to 
                                                                                                                       ## delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656644 = path.getOrDefault("name")
  valid_402656644 = validateParameter(valid_402656644, JString, required = true,
                                      default = nil)
  if valid_402656644 != nil:
    section.add "name", valid_402656644
  var valid_402656645 = path.getOrDefault("nodegroupName")
  valid_402656645 = validateParameter(valid_402656645, JString, required = true,
                                      default = nil)
  if valid_402656645 != nil:
    section.add "nodegroupName", valid_402656645
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656646 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Security-Token", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Signature")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Signature", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-Algorithm", valid_402656649
  var valid_402656650 = header.getOrDefault("X-Amz-Date")
  valid_402656650 = validateParameter(valid_402656650, JString,
                                      required = false, default = nil)
  if valid_402656650 != nil:
    section.add "X-Amz-Date", valid_402656650
  var valid_402656651 = header.getOrDefault("X-Amz-Credential")
  valid_402656651 = validateParameter(valid_402656651, JString,
                                      required = false, default = nil)
  if valid_402656651 != nil:
    section.add "X-Amz-Credential", valid_402656651
  var valid_402656652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656652 = validateParameter(valid_402656652, JString,
                                      required = false, default = nil)
  if valid_402656652 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656652
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656653: Call_DeleteNodegroup_402656641; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Amazon EKS node group for a cluster.
                                                                                         ## 
  let valid = call_402656653.validator(path, query, header, formData, body, _)
  let scheme = call_402656653.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656653.makeUrl(scheme.get, call_402656653.host, call_402656653.base,
                                   call_402656653.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656653, uri, valid, _)

proc call*(call_402656654: Call_DeleteNodegroup_402656641; name: string;
           nodegroupName: string): Recallable =
  ## deleteNodegroup
  ## Deletes an Amazon EKS node group for a cluster.
  ##   name: string (required)
                                                    ##       : The name of the Amazon EKS cluster that is associated with your node group.
  ##   
                                                                                                                                          ## nodegroupName: string (required)
                                                                                                                                          ##                
                                                                                                                                          ## : 
                                                                                                                                          ## The 
                                                                                                                                          ## name 
                                                                                                                                          ## of 
                                                                                                                                          ## the 
                                                                                                                                          ## node 
                                                                                                                                          ## group 
                                                                                                                                          ## to 
                                                                                                                                          ## delete.
  var path_402656655 = newJObject()
  add(path_402656655, "name", newJString(name))
  add(path_402656655, "nodegroupName", newJString(nodegroupName))
  result = call_402656654.call(path_402656655, nil, nil, nil, nil)

var deleteNodegroup* = Call_DeleteNodegroup_402656641(name: "deleteNodegroup",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DeleteNodegroup_402656642, base: "/",
    makeUrl: url_DeleteNodegroup_402656643, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUpdate_402656656 = ref object of OpenApiRestCall_402656044
proc url_DescribeUpdate_402656658(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "updateId" in path, "`updateId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/updates/"),
                 (kind: VariableSegment, value: "updateId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUpdate_402656657(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster associated with the update.
  ##   
                                                                                                          ## updateId: JString (required)
                                                                                                          ##           
                                                                                                          ## : 
                                                                                                          ## The 
                                                                                                          ## ID 
                                                                                                          ## of 
                                                                                                          ## the 
                                                                                                          ## update 
                                                                                                          ## to 
                                                                                                          ## describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656659 = path.getOrDefault("name")
  valid_402656659 = validateParameter(valid_402656659, JString, required = true,
                                      default = nil)
  if valid_402656659 != nil:
    section.add "name", valid_402656659
  var valid_402656660 = path.getOrDefault("updateId")
  valid_402656660 = validateParameter(valid_402656660, JString, required = true,
                                      default = nil)
  if valid_402656660 != nil:
    section.add "updateId", valid_402656660
  result.add "path", section
  ## parameters in `query` object:
  ##   nodegroupName: JString
                                  ##                : The name of the Amazon EKS node group associated with the update.
  section = newJObject()
  var valid_402656661 = query.getOrDefault("nodegroupName")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "nodegroupName", valid_402656661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656662 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Security-Token", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Signature")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Signature", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-Algorithm", valid_402656665
  var valid_402656666 = header.getOrDefault("X-Amz-Date")
  valid_402656666 = validateParameter(valid_402656666, JString,
                                      required = false, default = nil)
  if valid_402656666 != nil:
    section.add "X-Amz-Date", valid_402656666
  var valid_402656667 = header.getOrDefault("X-Amz-Credential")
  valid_402656667 = validateParameter(valid_402656667, JString,
                                      required = false, default = nil)
  if valid_402656667 != nil:
    section.add "X-Amz-Credential", valid_402656667
  var valid_402656668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656668 = validateParameter(valid_402656668, JString,
                                      required = false, default = nil)
  if valid_402656668 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656669: Call_DescribeUpdate_402656656; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
                                                                                         ## 
  let valid = call_402656669.validator(path, query, header, formData, body, _)
  let scheme = call_402656669.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656669.makeUrl(scheme.get, call_402656669.host, call_402656669.base,
                                   call_402656669.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656669, uri, valid, _)

proc call*(call_402656670: Call_DescribeUpdate_402656656; name: string;
           updateId: string; nodegroupName: string = ""): Recallable =
  ## describeUpdate
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                     ## name: string (required)
                                                                                                                                                                                                                                                                                                                                     ##       
                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                                                                                     ## name 
                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                                                                                                                     ## EKS 
                                                                                                                                                                                                                                                                                                                                     ## cluster 
                                                                                                                                                                                                                                                                                                                                     ## associated 
                                                                                                                                                                                                                                                                                                                                     ## with 
                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                     ## update.
  ##   
                                                                                                                                                                                                                                                                                                                                               ## nodegroupName: string
                                                                                                                                                                                                                                                                                                                                               ##                
                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                               ## The 
                                                                                                                                                                                                                                                                                                                                               ## name 
                                                                                                                                                                                                                                                                                                                                               ## of 
                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                               ## Amazon 
                                                                                                                                                                                                                                                                                                                                               ## EKS 
                                                                                                                                                                                                                                                                                                                                               ## node 
                                                                                                                                                                                                                                                                                                                                               ## group 
                                                                                                                                                                                                                                                                                                                                               ## associated 
                                                                                                                                                                                                                                                                                                                                               ## with 
                                                                                                                                                                                                                                                                                                                                               ## the 
                                                                                                                                                                                                                                                                                                                                               ## update.
  ##   
                                                                                                                                                                                                                                                                                                                                                         ## updateId: string (required)
                                                                                                                                                                                                                                                                                                                                                         ##           
                                                                                                                                                                                                                                                                                                                                                         ## : 
                                                                                                                                                                                                                                                                                                                                                         ## The 
                                                                                                                                                                                                                                                                                                                                                         ## ID 
                                                                                                                                                                                                                                                                                                                                                         ## of 
                                                                                                                                                                                                                                                                                                                                                         ## the 
                                                                                                                                                                                                                                                                                                                                                         ## update 
                                                                                                                                                                                                                                                                                                                                                         ## to 
                                                                                                                                                                                                                                                                                                                                                         ## describe.
  var path_402656671 = newJObject()
  var query_402656672 = newJObject()
  add(path_402656671, "name", newJString(name))
  add(query_402656672, "nodegroupName", newJString(nodegroupName))
  add(path_402656671, "updateId", newJString(updateId))
  result = call_402656670.call(path_402656671, query_402656672, nil, nil, nil)

var describeUpdate* = Call_DescribeUpdate_402656656(name: "describeUpdate",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/updates/{updateId}",
    validator: validate_DescribeUpdate_402656657, base: "/",
    makeUrl: url_DescribeUpdate_402656658, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656687 = ref object of OpenApiRestCall_402656044
proc url_TagResource_402656689(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656688(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) of the resource to which to add tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656690 = path.getOrDefault("resourceArn")
  valid_402656690 = validateParameter(valid_402656690, JString, required = true,
                                      default = nil)
  if valid_402656690 != nil:
    section.add "resourceArn", valid_402656690
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656691 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Security-Token", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Signature")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Signature", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Algorithm", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-Date")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-Date", valid_402656695
  var valid_402656696 = header.getOrDefault("X-Amz-Credential")
  valid_402656696 = validateParameter(valid_402656696, JString,
                                      required = false, default = nil)
  if valid_402656696 != nil:
    section.add "X-Amz-Credential", valid_402656696
  var valid_402656697 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656697 = validateParameter(valid_402656697, JString,
                                      required = false, default = nil)
  if valid_402656697 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656697
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656699: Call_TagResource_402656687; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
                                                                                         ## 
  let valid = call_402656699.validator(path, query, header, formData, body, _)
  let scheme = call_402656699.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656699.makeUrl(scheme.get, call_402656699.host, call_402656699.base,
                                   call_402656699.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656699, uri, valid, _)

proc call*(call_402656700: Call_TagResource_402656687; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## resourceArn: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##              
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## (ARN) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## resource 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## add 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## tags. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Currently, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## supported 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## resources 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## are 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## EKS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## clusters 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## managed 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## node 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## groups.
  var path_402656701 = newJObject()
  var body_402656702 = newJObject()
  if body != nil:
    body_402656702 = body
  add(path_402656701, "resourceArn", newJString(resourceArn))
  result = call_402656700.call(path_402656701, nil, nil, nil, body_402656702)

var tagResource* = Call_TagResource_402656687(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656688,
    base: "/", makeUrl: url_TagResource_402656689,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656673 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402656675(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656674(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the tags for an Amazon EKS resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656676 = path.getOrDefault("resourceArn")
  valid_402656676 = validateParameter(valid_402656676, JString, required = true,
                                      default = nil)
  if valid_402656676 != nil:
    section.add "resourceArn", valid_402656676
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656677 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Security-Token", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Signature")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Signature", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-Algorithm", valid_402656680
  var valid_402656681 = header.getOrDefault("X-Amz-Date")
  valid_402656681 = validateParameter(valid_402656681, JString,
                                      required = false, default = nil)
  if valid_402656681 != nil:
    section.add "X-Amz-Date", valid_402656681
  var valid_402656682 = header.getOrDefault("X-Amz-Credential")
  valid_402656682 = validateParameter(valid_402656682, JString,
                                      required = false, default = nil)
  if valid_402656682 != nil:
    section.add "X-Amz-Credential", valid_402656682
  var valid_402656683 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656683 = validateParameter(valid_402656683, JString,
                                      required = false, default = nil)
  if valid_402656683 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656683
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656684: Call_ListTagsForResource_402656673;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the tags for an Amazon EKS resource.
                                                                                         ## 
  let valid = call_402656684.validator(path, query, header, formData, body, _)
  let scheme = call_402656684.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656684.makeUrl(scheme.get, call_402656684.host, call_402656684.base,
                                   call_402656684.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656684, uri, valid, _)

proc call*(call_402656685: Call_ListTagsForResource_402656673;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon EKS resource.
  ##   resourceArn: string (required)
                                              ##              : The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_402656686 = newJObject()
  add(path_402656686, "resourceArn", newJString(resourceArn))
  result = call_402656685.call(path_402656686, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656673(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656674, base: "/",
    makeUrl: url_ListTagsForResource_402656675,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterVersion_402656721 = ref object of OpenApiRestCall_402656044
proc url_UpdateClusterVersion_402656723(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/updates")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateClusterVersion_402656722(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656724 = path.getOrDefault("name")
  valid_402656724 = validateParameter(valid_402656724, JString, required = true,
                                      default = nil)
  if valid_402656724 != nil:
    section.add "name", valid_402656724
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656725 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656725 = validateParameter(valid_402656725, JString,
                                      required = false, default = nil)
  if valid_402656725 != nil:
    section.add "X-Amz-Security-Token", valid_402656725
  var valid_402656726 = header.getOrDefault("X-Amz-Signature")
  valid_402656726 = validateParameter(valid_402656726, JString,
                                      required = false, default = nil)
  if valid_402656726 != nil:
    section.add "X-Amz-Signature", valid_402656726
  var valid_402656727 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656727 = validateParameter(valid_402656727, JString,
                                      required = false, default = nil)
  if valid_402656727 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656727
  var valid_402656728 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656728 = validateParameter(valid_402656728, JString,
                                      required = false, default = nil)
  if valid_402656728 != nil:
    section.add "X-Amz-Algorithm", valid_402656728
  var valid_402656729 = header.getOrDefault("X-Amz-Date")
  valid_402656729 = validateParameter(valid_402656729, JString,
                                      required = false, default = nil)
  if valid_402656729 != nil:
    section.add "X-Amz-Date", valid_402656729
  var valid_402656730 = header.getOrDefault("X-Amz-Credential")
  valid_402656730 = validateParameter(valid_402656730, JString,
                                      required = false, default = nil)
  if valid_402656730 != nil:
    section.add "X-Amz-Credential", valid_402656730
  var valid_402656731 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656731
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656733: Call_UpdateClusterVersion_402656721;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
                                                                                         ## 
  let valid = call_402656733.validator(path, query, header, formData, body, _)
  let scheme = call_402656733.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656733.makeUrl(scheme.get, call_402656733.host, call_402656733.base,
                                   call_402656733.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656733, uri, valid, _)

proc call*(call_402656734: Call_UpdateClusterVersion_402656721; name: string;
           body: JsonNode): Recallable =
  ## updateClusterVersion
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## EKS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## cluster 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## update.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var path_402656735 = newJObject()
  var body_402656736 = newJObject()
  add(path_402656735, "name", newJString(name))
  if body != nil:
    body_402656736 = body
  result = call_402656734.call(path_402656735, nil, nil, nil, body_402656736)

var updateClusterVersion* = Call_UpdateClusterVersion_402656721(
    name: "updateClusterVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/updates",
    validator: validate_UpdateClusterVersion_402656722, base: "/",
    makeUrl: url_UpdateClusterVersion_402656723,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUpdates_402656703 = ref object of OpenApiRestCall_402656044
proc url_ListUpdates_402656705(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/updates")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUpdates_402656704(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster to list updates for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656706 = path.getOrDefault("name")
  valid_402656706 = validateParameter(valid_402656706, JString, required = true,
                                      default = nil)
  if valid_402656706 != nil:
    section.add "name", valid_402656706
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of update results returned by <code>ListUpdates</code> in paginated output. When you use this parameter, <code>ListUpdates</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListUpdates</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListUpdates</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## nodegroupName: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## EKS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## managed 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## node 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## group 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## list 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## updates 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## for.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## nextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## paginated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## <code>ListUpdates</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## where 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## <code>maxResults</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## was 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## used 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## exceeded 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## value 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## parameter. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## continues 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## from 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## end 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## previous 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## returned 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## <code>nextToken</code> 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## value.
  section = newJObject()
  var valid_402656707 = query.getOrDefault("maxResults")
  valid_402656707 = validateParameter(valid_402656707, JInt, required = false,
                                      default = nil)
  if valid_402656707 != nil:
    section.add "maxResults", valid_402656707
  var valid_402656708 = query.getOrDefault("nodegroupName")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "nodegroupName", valid_402656708
  var valid_402656709 = query.getOrDefault("nextToken")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "nextToken", valid_402656709
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656710 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656710 = validateParameter(valid_402656710, JString,
                                      required = false, default = nil)
  if valid_402656710 != nil:
    section.add "X-Amz-Security-Token", valid_402656710
  var valid_402656711 = header.getOrDefault("X-Amz-Signature")
  valid_402656711 = validateParameter(valid_402656711, JString,
                                      required = false, default = nil)
  if valid_402656711 != nil:
    section.add "X-Amz-Signature", valid_402656711
  var valid_402656712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656712 = validateParameter(valid_402656712, JString,
                                      required = false, default = nil)
  if valid_402656712 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656712
  var valid_402656713 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656713 = validateParameter(valid_402656713, JString,
                                      required = false, default = nil)
  if valid_402656713 != nil:
    section.add "X-Amz-Algorithm", valid_402656713
  var valid_402656714 = header.getOrDefault("X-Amz-Date")
  valid_402656714 = validateParameter(valid_402656714, JString,
                                      required = false, default = nil)
  if valid_402656714 != nil:
    section.add "X-Amz-Date", valid_402656714
  var valid_402656715 = header.getOrDefault("X-Amz-Credential")
  valid_402656715 = validateParameter(valid_402656715, JString,
                                      required = false, default = nil)
  if valid_402656715 != nil:
    section.add "X-Amz-Credential", valid_402656715
  var valid_402656716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656716 = validateParameter(valid_402656716, JString,
                                      required = false, default = nil)
  if valid_402656716 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656717: Call_ListUpdates_402656703; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
                                                                                         ## 
  let valid = call_402656717.validator(path, query, header, formData, body, _)
  let scheme = call_402656717.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656717.makeUrl(scheme.get, call_402656717.host, call_402656717.base,
                                   call_402656717.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656717, uri, valid, _)

proc call*(call_402656718: Call_ListUpdates_402656703; name: string;
           maxResults: int = 0; nodegroupName: string = "";
           nextToken: string = ""): Recallable =
  ## listUpdates
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
  ##   
                                                                                                                                ## maxResults: int
                                                                                                                                ##             
                                                                                                                                ## : 
                                                                                                                                ## The 
                                                                                                                                ## maximum 
                                                                                                                                ## number 
                                                                                                                                ## of 
                                                                                                                                ## update 
                                                                                                                                ## results 
                                                                                                                                ## returned 
                                                                                                                                ## by 
                                                                                                                                ## <code>ListUpdates</code> 
                                                                                                                                ## in 
                                                                                                                                ## paginated 
                                                                                                                                ## output. 
                                                                                                                                ## When 
                                                                                                                                ## you 
                                                                                                                                ## use 
                                                                                                                                ## this 
                                                                                                                                ## parameter, 
                                                                                                                                ## <code>ListUpdates</code> 
                                                                                                                                ## returns 
                                                                                                                                ## only 
                                                                                                                                ## <code>maxResults</code> 
                                                                                                                                ## results 
                                                                                                                                ## in 
                                                                                                                                ## a 
                                                                                                                                ## single 
                                                                                                                                ## page 
                                                                                                                                ## along 
                                                                                                                                ## with 
                                                                                                                                ## a 
                                                                                                                                ## <code>nextToken</code> 
                                                                                                                                ## response 
                                                                                                                                ## element. 
                                                                                                                                ## You 
                                                                                                                                ## can 
                                                                                                                                ## see 
                                                                                                                                ## the 
                                                                                                                                ## remaining 
                                                                                                                                ## results 
                                                                                                                                ## of 
                                                                                                                                ## the 
                                                                                                                                ## initial 
                                                                                                                                ## request 
                                                                                                                                ## by 
                                                                                                                                ## sending 
                                                                                                                                ## another 
                                                                                                                                ## <code>ListUpdates</code> 
                                                                                                                                ## request 
                                                                                                                                ## with 
                                                                                                                                ## the 
                                                                                                                                ## returned 
                                                                                                                                ## <code>nextToken</code> 
                                                                                                                                ## value. 
                                                                                                                                ## This 
                                                                                                                                ## value 
                                                                                                                                ## can 
                                                                                                                                ## be 
                                                                                                                                ## between 
                                                                                                                                ## 1 
                                                                                                                                ## and 
                                                                                                                                ## 100. 
                                                                                                                                ## If 
                                                                                                                                ## you 
                                                                                                                                ## don't 
                                                                                                                                ## use 
                                                                                                                                ## this 
                                                                                                                                ## parameter, 
                                                                                                                                ## <code>ListUpdates</code> 
                                                                                                                                ## returns 
                                                                                                                                ## up 
                                                                                                                                ## to 
                                                                                                                                ## 100 
                                                                                                                                ## results 
                                                                                                                                ## and 
                                                                                                                                ## a 
                                                                                                                                ## <code>nextToken</code> 
                                                                                                                                ## value 
                                                                                                                                ## if 
                                                                                                                                ## applicable.
  ##   
                                                                                                                                              ## name: string (required)
                                                                                                                                              ##       
                                                                                                                                              ## : 
                                                                                                                                              ## The 
                                                                                                                                              ## name 
                                                                                                                                              ## of 
                                                                                                                                              ## the 
                                                                                                                                              ## Amazon 
                                                                                                                                              ## EKS 
                                                                                                                                              ## cluster 
                                                                                                                                              ## to 
                                                                                                                                              ## list 
                                                                                                                                              ## updates 
                                                                                                                                              ## for.
  ##   
                                                                                                                                                     ## nodegroupName: string
                                                                                                                                                     ##                
                                                                                                                                                     ## : 
                                                                                                                                                     ## The 
                                                                                                                                                     ## name 
                                                                                                                                                     ## of 
                                                                                                                                                     ## the 
                                                                                                                                                     ## Amazon 
                                                                                                                                                     ## EKS 
                                                                                                                                                     ## managed 
                                                                                                                                                     ## node 
                                                                                                                                                     ## group 
                                                                                                                                                     ## to 
                                                                                                                                                     ## list 
                                                                                                                                                     ## updates 
                                                                                                                                                     ## for.
  ##   
                                                                                                                                                            ## nextToken: string
                                                                                                                                                            ##            
                                                                                                                                                            ## : 
                                                                                                                                                            ## The 
                                                                                                                                                            ## <code>nextToken</code> 
                                                                                                                                                            ## value 
                                                                                                                                                            ## returned 
                                                                                                                                                            ## from 
                                                                                                                                                            ## a 
                                                                                                                                                            ## previous 
                                                                                                                                                            ## paginated 
                                                                                                                                                            ## <code>ListUpdates</code> 
                                                                                                                                                            ## request 
                                                                                                                                                            ## where 
                                                                                                                                                            ## <code>maxResults</code> 
                                                                                                                                                            ## was 
                                                                                                                                                            ## used 
                                                                                                                                                            ## and 
                                                                                                                                                            ## the 
                                                                                                                                                            ## results 
                                                                                                                                                            ## exceeded 
                                                                                                                                                            ## the 
                                                                                                                                                            ## value 
                                                                                                                                                            ## of 
                                                                                                                                                            ## that 
                                                                                                                                                            ## parameter. 
                                                                                                                                                            ## Pagination 
                                                                                                                                                            ## continues 
                                                                                                                                                            ## from 
                                                                                                                                                            ## the 
                                                                                                                                                            ## end 
                                                                                                                                                            ## of 
                                                                                                                                                            ## the 
                                                                                                                                                            ## previous 
                                                                                                                                                            ## results 
                                                                                                                                                            ## that 
                                                                                                                                                            ## returned 
                                                                                                                                                            ## the 
                                                                                                                                                            ## <code>nextToken</code> 
                                                                                                                                                            ## value.
  var path_402656719 = newJObject()
  var query_402656720 = newJObject()
  add(query_402656720, "maxResults", newJInt(maxResults))
  add(path_402656719, "name", newJString(name))
  add(query_402656720, "nodegroupName", newJString(nodegroupName))
  add(query_402656720, "nextToken", newJString(nextToken))
  result = call_402656718.call(path_402656719, query_402656720, nil, nil, nil)

var listUpdates* = Call_ListUpdates_402656703(name: "listUpdates",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/updates", validator: validate_ListUpdates_402656704,
    base: "/", makeUrl: url_ListUpdates_402656705,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656737 = ref object of OpenApiRestCall_402656044
proc url_UntagResource_402656739(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656738(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes specified tags from a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) of the resource from which to delete tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656740 = path.getOrDefault("resourceArn")
  valid_402656740 = validateParameter(valid_402656740, JString, required = true,
                                      default = nil)
  if valid_402656740 != nil:
    section.add "resourceArn", valid_402656740
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656741 = query.getOrDefault("tagKeys")
  valid_402656741 = validateParameter(valid_402656741, JArray, required = true,
                                      default = nil)
  if valid_402656741 != nil:
    section.add "tagKeys", valid_402656741
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656742 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656742 = validateParameter(valid_402656742, JString,
                                      required = false, default = nil)
  if valid_402656742 != nil:
    section.add "X-Amz-Security-Token", valid_402656742
  var valid_402656743 = header.getOrDefault("X-Amz-Signature")
  valid_402656743 = validateParameter(valid_402656743, JString,
                                      required = false, default = nil)
  if valid_402656743 != nil:
    section.add "X-Amz-Signature", valid_402656743
  var valid_402656744 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656744 = validateParameter(valid_402656744, JString,
                                      required = false, default = nil)
  if valid_402656744 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656744
  var valid_402656745 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Algorithm", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Date")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Date", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Credential")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Credential", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656748
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656749: Call_UntagResource_402656737; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes specified tags from a resource.
                                                                                         ## 
  let valid = call_402656749.validator(path, query, header, formData, body, _)
  let scheme = call_402656749.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656749.makeUrl(scheme.get, call_402656749.host, call_402656749.base,
                                   call_402656749.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656749, uri, valid, _)

proc call*(call_402656750: Call_UntagResource_402656737; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   tagKeys: JArray (required)
                                            ##          : The keys of the tags to be removed.
  ##   
                                                                                             ## resourceArn: string (required)
                                                                                             ##              
                                                                                             ## : 
                                                                                             ## The 
                                                                                             ## Amazon 
                                                                                             ## Resource 
                                                                                             ## Name 
                                                                                             ## (ARN) 
                                                                                             ## of 
                                                                                             ## the 
                                                                                             ## resource 
                                                                                             ## from 
                                                                                             ## which 
                                                                                             ## to 
                                                                                             ## delete 
                                                                                             ## tags. 
                                                                                             ## Currently, 
                                                                                             ## the 
                                                                                             ## supported 
                                                                                             ## resources 
                                                                                             ## are 
                                                                                             ## Amazon 
                                                                                             ## EKS 
                                                                                             ## clusters 
                                                                                             ## and 
                                                                                             ## managed 
                                                                                             ## node 
                                                                                             ## groups.
  var path_402656751 = newJObject()
  var query_402656752 = newJObject()
  if tagKeys != nil:
    query_402656752.add "tagKeys", tagKeys
  add(path_402656751, "resourceArn", newJString(resourceArn))
  result = call_402656750.call(path_402656751, query_402656752, nil, nil, nil)

var untagResource* = Call_UntagResource_402656737(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656738,
    base: "/", makeUrl: url_UntagResource_402656739,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfig_402656753 = ref object of OpenApiRestCall_402656044
proc url_UpdateClusterConfig_402656755(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/update-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateClusterConfig_402656754(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656756 = path.getOrDefault("name")
  valid_402656756 = validateParameter(valid_402656756, JString, required = true,
                                      default = nil)
  if valid_402656756 != nil:
    section.add "name", valid_402656756
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656757 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656757 = validateParameter(valid_402656757, JString,
                                      required = false, default = nil)
  if valid_402656757 != nil:
    section.add "X-Amz-Security-Token", valid_402656757
  var valid_402656758 = header.getOrDefault("X-Amz-Signature")
  valid_402656758 = validateParameter(valid_402656758, JString,
                                      required = false, default = nil)
  if valid_402656758 != nil:
    section.add "X-Amz-Signature", valid_402656758
  var valid_402656759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656759 = validateParameter(valid_402656759, JString,
                                      required = false, default = nil)
  if valid_402656759 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656759
  var valid_402656760 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656760 = validateParameter(valid_402656760, JString,
                                      required = false, default = nil)
  if valid_402656760 != nil:
    section.add "X-Amz-Algorithm", valid_402656760
  var valid_402656761 = header.getOrDefault("X-Amz-Date")
  valid_402656761 = validateParameter(valid_402656761, JString,
                                      required = false, default = nil)
  if valid_402656761 != nil:
    section.add "X-Amz-Date", valid_402656761
  var valid_402656762 = header.getOrDefault("X-Amz-Credential")
  valid_402656762 = validateParameter(valid_402656762, JString,
                                      required = false, default = nil)
  if valid_402656762 != nil:
    section.add "X-Amz-Credential", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656765: Call_UpdateClusterConfig_402656753;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
                                                                                         ## 
  let valid = call_402656765.validator(path, query, header, formData, body, _)
  let scheme = call_402656765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656765.makeUrl(scheme.get, call_402656765.host, call_402656765.base,
                                   call_402656765.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656765, uri, valid, _)

proc call*(call_402656766: Call_UpdateClusterConfig_402656753; name: string;
           body: JsonNode): Recallable =
  ## updateClusterConfig
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## EKS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## cluster 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## update.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var path_402656767 = newJObject()
  var body_402656768 = newJObject()
  add(path_402656767, "name", newJString(name))
  if body != nil:
    body_402656768 = body
  result = call_402656766.call(path_402656767, nil, nil, nil, body_402656768)

var updateClusterConfig* = Call_UpdateClusterConfig_402656753(
    name: "updateClusterConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/update-config",
    validator: validate_UpdateClusterConfig_402656754, base: "/",
    makeUrl: url_UpdateClusterConfig_402656755,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupConfig_402656769 = ref object of OpenApiRestCall_402656044
proc url_UpdateNodegroupConfig_402656771(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "nodegroupName" in path, "`nodegroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/node-groups/"),
                 (kind: VariableSegment, value: "nodegroupName"),
                 (kind: ConstantSegment, value: "/update-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateNodegroupConfig_402656770(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster that the managed node group resides in.
  ##   
                                                                                                                      ## nodegroupName: JString (required)
                                                                                                                      ##                
                                                                                                                      ## : 
                                                                                                                      ## The 
                                                                                                                      ## name 
                                                                                                                      ## of 
                                                                                                                      ## the 
                                                                                                                      ## managed 
                                                                                                                      ## node 
                                                                                                                      ## group 
                                                                                                                      ## to 
                                                                                                                      ## update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656772 = path.getOrDefault("name")
  valid_402656772 = validateParameter(valid_402656772, JString, required = true,
                                      default = nil)
  if valid_402656772 != nil:
    section.add "name", valid_402656772
  var valid_402656773 = path.getOrDefault("nodegroupName")
  valid_402656773 = validateParameter(valid_402656773, JString, required = true,
                                      default = nil)
  if valid_402656773 != nil:
    section.add "nodegroupName", valid_402656773
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656774 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656774 = validateParameter(valid_402656774, JString,
                                      required = false, default = nil)
  if valid_402656774 != nil:
    section.add "X-Amz-Security-Token", valid_402656774
  var valid_402656775 = header.getOrDefault("X-Amz-Signature")
  valid_402656775 = validateParameter(valid_402656775, JString,
                                      required = false, default = nil)
  if valid_402656775 != nil:
    section.add "X-Amz-Signature", valid_402656775
  var valid_402656776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656776 = validateParameter(valid_402656776, JString,
                                      required = false, default = nil)
  if valid_402656776 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656776
  var valid_402656777 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656777 = validateParameter(valid_402656777, JString,
                                      required = false, default = nil)
  if valid_402656777 != nil:
    section.add "X-Amz-Algorithm", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Date")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Date", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Credential")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Credential", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656782: Call_UpdateNodegroupConfig_402656769;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
                                                                                         ## 
  let valid = call_402656782.validator(path, query, header, formData, body, _)
  let scheme = call_402656782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656782.makeUrl(scheme.get, call_402656782.host, call_402656782.base,
                                   call_402656782.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656782, uri, valid, _)

proc call*(call_402656783: Call_UpdateNodegroupConfig_402656769; name: string;
           body: JsonNode; nodegroupName: string): Recallable =
  ## updateNodegroupConfig
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ##   
                                                                                                                                                                                                                                                                                                                                                                          ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                          ##       
                                                                                                                                                                                                                                                                                                                                                                          ## : 
                                                                                                                                                                                                                                                                                                                                                                          ## The 
                                                                                                                                                                                                                                                                                                                                                                          ## name 
                                                                                                                                                                                                                                                                                                                                                                          ## of 
                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                          ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                          ## EKS 
                                                                                                                                                                                                                                                                                                                                                                          ## cluster 
                                                                                                                                                                                                                                                                                                                                                                          ## that 
                                                                                                                                                                                                                                                                                                                                                                          ## the 
                                                                                                                                                                                                                                                                                                                                                                          ## managed 
                                                                                                                                                                                                                                                                                                                                                                          ## node 
                                                                                                                                                                                                                                                                                                                                                                          ## group 
                                                                                                                                                                                                                                                                                                                                                                          ## resides 
                                                                                                                                                                                                                                                                                                                                                                          ## in.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                           ## nodegroupName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                           ##                
                                                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                                                           ## The 
                                                                                                                                                                                                                                                                                                                                                                                                           ## name 
                                                                                                                                                                                                                                                                                                                                                                                                           ## of 
                                                                                                                                                                                                                                                                                                                                                                                                           ## the 
                                                                                                                                                                                                                                                                                                                                                                                                           ## managed 
                                                                                                                                                                                                                                                                                                                                                                                                           ## node 
                                                                                                                                                                                                                                                                                                                                                                                                           ## group 
                                                                                                                                                                                                                                                                                                                                                                                                           ## to 
                                                                                                                                                                                                                                                                                                                                                                                                           ## update.
  var path_402656784 = newJObject()
  var body_402656785 = newJObject()
  add(path_402656784, "name", newJString(name))
  if body != nil:
    body_402656785 = body
  add(path_402656784, "nodegroupName", newJString(nodegroupName))
  result = call_402656783.call(path_402656784, nil, nil, nil, body_402656785)

var updateNodegroupConfig* = Call_UpdateNodegroupConfig_402656769(
    name: "updateNodegroupConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-config",
    validator: validate_UpdateNodegroupConfig_402656770, base: "/",
    makeUrl: url_UpdateNodegroupConfig_402656771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupVersion_402656786 = ref object of OpenApiRestCall_402656044
proc url_UpdateNodegroupVersion_402656788(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "name" in path, "`name` is a required path parameter"
  assert "nodegroupName" in path, "`nodegroupName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/clusters/"),
                 (kind: VariableSegment, value: "name"),
                 (kind: ConstantSegment, value: "/node-groups/"),
                 (kind: VariableSegment, value: "nodegroupName"),
                 (kind: ConstantSegment, value: "/update-version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateNodegroupVersion_402656787(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
                                 ##       : The name of the Amazon EKS cluster that is associated with the managed node group to update.
  ##   
                                                                                                                                        ## nodegroupName: JString (required)
                                                                                                                                        ##                
                                                                                                                                        ## : 
                                                                                                                                        ## The 
                                                                                                                                        ## name 
                                                                                                                                        ## of 
                                                                                                                                        ## the 
                                                                                                                                        ## managed 
                                                                                                                                        ## node 
                                                                                                                                        ## group 
                                                                                                                                        ## to 
                                                                                                                                        ## update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_402656789 = path.getOrDefault("name")
  valid_402656789 = validateParameter(valid_402656789, JString, required = true,
                                      default = nil)
  if valid_402656789 != nil:
    section.add "name", valid_402656789
  var valid_402656790 = path.getOrDefault("nodegroupName")
  valid_402656790 = validateParameter(valid_402656790, JString, required = true,
                                      default = nil)
  if valid_402656790 != nil:
    section.add "nodegroupName", valid_402656790
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656791 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656791 = validateParameter(valid_402656791, JString,
                                      required = false, default = nil)
  if valid_402656791 != nil:
    section.add "X-Amz-Security-Token", valid_402656791
  var valid_402656792 = header.getOrDefault("X-Amz-Signature")
  valid_402656792 = validateParameter(valid_402656792, JString,
                                      required = false, default = nil)
  if valid_402656792 != nil:
    section.add "X-Amz-Signature", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Algorithm", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Date")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Date", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Credential")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Credential", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656797
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656799: Call_UpdateNodegroupVersion_402656786;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
                                                                                         ## 
  let valid = call_402656799.validator(path, query, header, formData, body, _)
  let scheme = call_402656799.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656799.makeUrl(scheme.get, call_402656799.host, call_402656799.base,
                                   call_402656799.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656799, uri, valid, _)

proc call*(call_402656800: Call_UpdateNodegroupVersion_402656786; name: string;
           body: JsonNode; nodegroupName: string): Recallable =
  ## updateNodegroupVersion
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## name: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ##       
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## Amazon 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## EKS 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## cluster 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## is 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## associated 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## managed 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## node 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## group 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## update.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## nodegroupName: string (required)
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ##                
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## name 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## managed 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## node 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## group 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## update.
  var path_402656801 = newJObject()
  var body_402656802 = newJObject()
  add(path_402656801, "name", newJString(name))
  if body != nil:
    body_402656802 = body
  add(path_402656801, "nodegroupName", newJString(nodegroupName))
  result = call_402656800.call(path_402656801, nil, nil, nil, body_402656802)

var updateNodegroupVersion* = Call_UpdateNodegroupVersion_402656786(
    name: "updateNodegroupVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-version",
    validator: validate_UpdateNodegroupVersion_402656787, base: "/",
    makeUrl: url_UpdateNodegroupVersion_402656788,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}