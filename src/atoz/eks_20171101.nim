
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_604659 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_604659](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_604659): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
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
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "eks.ap-northeast-1.amazonaws.com", "ap-southeast-1": "eks.ap-southeast-1.amazonaws.com",
                           "us-west-2": "eks.us-west-2.amazonaws.com",
                           "eu-west-2": "eks.eu-west-2.amazonaws.com", "ap-northeast-3": "eks.ap-northeast-3.amazonaws.com",
                           "eu-central-1": "eks.eu-central-1.amazonaws.com",
                           "us-east-2": "eks.us-east-2.amazonaws.com",
                           "us-east-1": "eks.us-east-1.amazonaws.com", "cn-northwest-1": "eks.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "eks.ap-south-1.amazonaws.com",
                           "eu-north-1": "eks.eu-north-1.amazonaws.com", "ap-northeast-2": "eks.ap-northeast-2.amazonaws.com",
                           "us-west-1": "eks.us-west-1.amazonaws.com",
                           "us-gov-east-1": "eks.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "eks.eu-west-3.amazonaws.com",
                           "cn-north-1": "eks.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "eks.sa-east-1.amazonaws.com",
                           "eu-west-1": "eks.eu-west-1.amazonaws.com",
                           "us-gov-west-1": "eks.us-gov-west-1.amazonaws.com", "ap-southeast-2": "eks.ap-southeast-2.amazonaws.com",
                           "ca-central-1": "eks.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateCluster_605254 = ref object of OpenApiRestCall_604659
proc url_CreateCluster_605256(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_605255(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605257 = header.getOrDefault("X-Amz-Signature")
  valid_605257 = validateParameter(valid_605257, JString, required = false,
                                 default = nil)
  if valid_605257 != nil:
    section.add "X-Amz-Signature", valid_605257
  var valid_605258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605258 = validateParameter(valid_605258, JString, required = false,
                                 default = nil)
  if valid_605258 != nil:
    section.add "X-Amz-Content-Sha256", valid_605258
  var valid_605259 = header.getOrDefault("X-Amz-Date")
  valid_605259 = validateParameter(valid_605259, JString, required = false,
                                 default = nil)
  if valid_605259 != nil:
    section.add "X-Amz-Date", valid_605259
  var valid_605260 = header.getOrDefault("X-Amz-Credential")
  valid_605260 = validateParameter(valid_605260, JString, required = false,
                                 default = nil)
  if valid_605260 != nil:
    section.add "X-Amz-Credential", valid_605260
  var valid_605261 = header.getOrDefault("X-Amz-Security-Token")
  valid_605261 = validateParameter(valid_605261, JString, required = false,
                                 default = nil)
  if valid_605261 != nil:
    section.add "X-Amz-Security-Token", valid_605261
  var valid_605262 = header.getOrDefault("X-Amz-Algorithm")
  valid_605262 = validateParameter(valid_605262, JString, required = false,
                                 default = nil)
  if valid_605262 != nil:
    section.add "X-Amz-Algorithm", valid_605262
  var valid_605263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605263 = validateParameter(valid_605263, JString, required = false,
                                 default = nil)
  if valid_605263 != nil:
    section.add "X-Amz-SignedHeaders", valid_605263
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605265: Call_CreateCluster_605254; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  let valid = call_605265.validator(path, query, header, formData, body)
  let scheme = call_605265.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605265.url(scheme.get, call_605265.host, call_605265.base,
                         call_605265.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605265, url, valid)

proc call*(call_605266: Call_CreateCluster_605254; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   body: JObject (required)
  var body_605267 = newJObject()
  if body != nil:
    body_605267 = body
  result = call_605266.call(nil, nil, nil, nil, body_605267)

var createCluster* = Call_CreateCluster_605254(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_CreateCluster_605255, base: "/", url: url_CreateCluster_605256,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_604997 = ref object of OpenApiRestCall_604659
proc url_ListClusters_604999(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListClusters_604998(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListClusters</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.</p> <note> <p>This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  ##   maxResults: JInt
  ##             : The maximum number of cluster results returned by <code>ListClusters</code> in paginated output. When you use this parameter, <code>ListClusters</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListClusters</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListClusters</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_605111 = query.getOrDefault("nextToken")
  valid_605111 = validateParameter(valid_605111, JString, required = false,
                                 default = nil)
  if valid_605111 != nil:
    section.add "nextToken", valid_605111
  var valid_605112 = query.getOrDefault("maxResults")
  valid_605112 = validateParameter(valid_605112, JInt, required = false, default = nil)
  if valid_605112 != nil:
    section.add "maxResults", valid_605112
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605113 = header.getOrDefault("X-Amz-Signature")
  valid_605113 = validateParameter(valid_605113, JString, required = false,
                                 default = nil)
  if valid_605113 != nil:
    section.add "X-Amz-Signature", valid_605113
  var valid_605114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605114 = validateParameter(valid_605114, JString, required = false,
                                 default = nil)
  if valid_605114 != nil:
    section.add "X-Amz-Content-Sha256", valid_605114
  var valid_605115 = header.getOrDefault("X-Amz-Date")
  valid_605115 = validateParameter(valid_605115, JString, required = false,
                                 default = nil)
  if valid_605115 != nil:
    section.add "X-Amz-Date", valid_605115
  var valid_605116 = header.getOrDefault("X-Amz-Credential")
  valid_605116 = validateParameter(valid_605116, JString, required = false,
                                 default = nil)
  if valid_605116 != nil:
    section.add "X-Amz-Credential", valid_605116
  var valid_605117 = header.getOrDefault("X-Amz-Security-Token")
  valid_605117 = validateParameter(valid_605117, JString, required = false,
                                 default = nil)
  if valid_605117 != nil:
    section.add "X-Amz-Security-Token", valid_605117
  var valid_605118 = header.getOrDefault("X-Amz-Algorithm")
  valid_605118 = validateParameter(valid_605118, JString, required = false,
                                 default = nil)
  if valid_605118 != nil:
    section.add "X-Amz-Algorithm", valid_605118
  var valid_605119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605119 = validateParameter(valid_605119, JString, required = false,
                                 default = nil)
  if valid_605119 != nil:
    section.add "X-Amz-SignedHeaders", valid_605119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605142: Call_ListClusters_604997; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ## 
  let valid = call_605142.validator(path, query, header, formData, body)
  let scheme = call_605142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605142.url(scheme.get, call_605142.host, call_605142.base,
                         call_605142.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605142, url, valid)

proc call*(call_605213: Call_ListClusters_604997; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listClusters
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ##   nextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListClusters</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.</p> <note> <p>This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  ##   maxResults: int
  ##             : The maximum number of cluster results returned by <code>ListClusters</code> in paginated output. When you use this parameter, <code>ListClusters</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListClusters</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListClusters</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var query_605214 = newJObject()
  add(query_605214, "nextToken", newJString(nextToken))
  add(query_605214, "maxResults", newJInt(maxResults))
  result = call_605213.call(nil, query_605214, nil, nil, nil)

var listClusters* = Call_ListClusters_604997(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_ListClusters_604998, base: "/", url: url_ListClusters_604999,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFargateProfile_605299 = ref object of OpenApiRestCall_604659
proc url_CreateFargateProfile_605301(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFargateProfile_605300(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster to apply the Fargate profile to.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605302 = path.getOrDefault("name")
  valid_605302 = validateParameter(valid_605302, JString, required = true,
                                 default = nil)
  if valid_605302 != nil:
    section.add "name", valid_605302
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605303 = header.getOrDefault("X-Amz-Signature")
  valid_605303 = validateParameter(valid_605303, JString, required = false,
                                 default = nil)
  if valid_605303 != nil:
    section.add "X-Amz-Signature", valid_605303
  var valid_605304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605304 = validateParameter(valid_605304, JString, required = false,
                                 default = nil)
  if valid_605304 != nil:
    section.add "X-Amz-Content-Sha256", valid_605304
  var valid_605305 = header.getOrDefault("X-Amz-Date")
  valid_605305 = validateParameter(valid_605305, JString, required = false,
                                 default = nil)
  if valid_605305 != nil:
    section.add "X-Amz-Date", valid_605305
  var valid_605306 = header.getOrDefault("X-Amz-Credential")
  valid_605306 = validateParameter(valid_605306, JString, required = false,
                                 default = nil)
  if valid_605306 != nil:
    section.add "X-Amz-Credential", valid_605306
  var valid_605307 = header.getOrDefault("X-Amz-Security-Token")
  valid_605307 = validateParameter(valid_605307, JString, required = false,
                                 default = nil)
  if valid_605307 != nil:
    section.add "X-Amz-Security-Token", valid_605307
  var valid_605308 = header.getOrDefault("X-Amz-Algorithm")
  valid_605308 = validateParameter(valid_605308, JString, required = false,
                                 default = nil)
  if valid_605308 != nil:
    section.add "X-Amz-Algorithm", valid_605308
  var valid_605309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605309 = validateParameter(valid_605309, JString, required = false,
                                 default = nil)
  if valid_605309 != nil:
    section.add "X-Amz-SignedHeaders", valid_605309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605311: Call_CreateFargateProfile_605299; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  let valid = call_605311.validator(path, query, header, formData, body)
  let scheme = call_605311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605311.url(scheme.get, call_605311.host, call_605311.base,
                         call_605311.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605311, url, valid)

proc call*(call_605312: Call_CreateFargateProfile_605299; name: string;
          body: JsonNode): Recallable =
  ## createFargateProfile
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to apply the Fargate profile to.
  ##   body: JObject (required)
  var path_605313 = newJObject()
  var body_605314 = newJObject()
  add(path_605313, "name", newJString(name))
  if body != nil:
    body_605314 = body
  result = call_605312.call(path_605313, nil, nil, nil, body_605314)

var createFargateProfile* = Call_CreateFargateProfile_605299(
    name: "createFargateProfile", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_CreateFargateProfile_605300, base: "/",
    url: url_CreateFargateProfile_605301, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFargateProfiles_605268 = ref object of OpenApiRestCall_604659
proc url_ListFargateProfiles_605270(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFargateProfiles_605269(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster that you would like to listFargate profiles in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605285 = path.getOrDefault("name")
  valid_605285 = validateParameter(valid_605285, JString, required = true,
                                 default = nil)
  if valid_605285 != nil:
    section.add "name", valid_605285
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListFargateProfiles</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   maxResults: JInt
  ##             : The maximum number of Fargate profile results returned by <code>ListFargateProfiles</code> in paginated output. When you use this parameter, <code>ListFargateProfiles</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListFargateProfiles</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListFargateProfiles</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_605286 = query.getOrDefault("nextToken")
  valid_605286 = validateParameter(valid_605286, JString, required = false,
                                 default = nil)
  if valid_605286 != nil:
    section.add "nextToken", valid_605286
  var valid_605287 = query.getOrDefault("maxResults")
  valid_605287 = validateParameter(valid_605287, JInt, required = false, default = nil)
  if valid_605287 != nil:
    section.add "maxResults", valid_605287
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605288 = header.getOrDefault("X-Amz-Signature")
  valid_605288 = validateParameter(valid_605288, JString, required = false,
                                 default = nil)
  if valid_605288 != nil:
    section.add "X-Amz-Signature", valid_605288
  var valid_605289 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605289 = validateParameter(valid_605289, JString, required = false,
                                 default = nil)
  if valid_605289 != nil:
    section.add "X-Amz-Content-Sha256", valid_605289
  var valid_605290 = header.getOrDefault("X-Amz-Date")
  valid_605290 = validateParameter(valid_605290, JString, required = false,
                                 default = nil)
  if valid_605290 != nil:
    section.add "X-Amz-Date", valid_605290
  var valid_605291 = header.getOrDefault("X-Amz-Credential")
  valid_605291 = validateParameter(valid_605291, JString, required = false,
                                 default = nil)
  if valid_605291 != nil:
    section.add "X-Amz-Credential", valid_605291
  var valid_605292 = header.getOrDefault("X-Amz-Security-Token")
  valid_605292 = validateParameter(valid_605292, JString, required = false,
                                 default = nil)
  if valid_605292 != nil:
    section.add "X-Amz-Security-Token", valid_605292
  var valid_605293 = header.getOrDefault("X-Amz-Algorithm")
  valid_605293 = validateParameter(valid_605293, JString, required = false,
                                 default = nil)
  if valid_605293 != nil:
    section.add "X-Amz-Algorithm", valid_605293
  var valid_605294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605294 = validateParameter(valid_605294, JString, required = false,
                                 default = nil)
  if valid_605294 != nil:
    section.add "X-Amz-SignedHeaders", valid_605294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605295: Call_ListFargateProfiles_605268; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ## 
  let valid = call_605295.validator(path, query, header, formData, body)
  let scheme = call_605295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605295.url(scheme.get, call_605295.host, call_605295.base,
                         call_605295.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605295, url, valid)

proc call*(call_605296: Call_ListFargateProfiles_605268; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listFargateProfiles
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListFargateProfiles</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that you would like to listFargate profiles in.
  ##   maxResults: int
  ##             : The maximum number of Fargate profile results returned by <code>ListFargateProfiles</code> in paginated output. When you use this parameter, <code>ListFargateProfiles</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListFargateProfiles</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListFargateProfiles</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var path_605297 = newJObject()
  var query_605298 = newJObject()
  add(query_605298, "nextToken", newJString(nextToken))
  add(path_605297, "name", newJString(name))
  add(query_605298, "maxResults", newJInt(maxResults))
  result = call_605296.call(path_605297, query_605298, nil, nil, nil)

var listFargateProfiles* = Call_ListFargateProfiles_605268(
    name: "listFargateProfiles", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_ListFargateProfiles_605269, base: "/",
    url: url_ListFargateProfiles_605270, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNodegroup_605332 = ref object of OpenApiRestCall_604659
proc url_CreateNodegroup_605334(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateNodegroup_605333(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the cluster to create the node group in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605335 = path.getOrDefault("name")
  valid_605335 = validateParameter(valid_605335, JString, required = true,
                                 default = nil)
  if valid_605335 != nil:
    section.add "name", valid_605335
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605336 = header.getOrDefault("X-Amz-Signature")
  valid_605336 = validateParameter(valid_605336, JString, required = false,
                                 default = nil)
  if valid_605336 != nil:
    section.add "X-Amz-Signature", valid_605336
  var valid_605337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605337 = validateParameter(valid_605337, JString, required = false,
                                 default = nil)
  if valid_605337 != nil:
    section.add "X-Amz-Content-Sha256", valid_605337
  var valid_605338 = header.getOrDefault("X-Amz-Date")
  valid_605338 = validateParameter(valid_605338, JString, required = false,
                                 default = nil)
  if valid_605338 != nil:
    section.add "X-Amz-Date", valid_605338
  var valid_605339 = header.getOrDefault("X-Amz-Credential")
  valid_605339 = validateParameter(valid_605339, JString, required = false,
                                 default = nil)
  if valid_605339 != nil:
    section.add "X-Amz-Credential", valid_605339
  var valid_605340 = header.getOrDefault("X-Amz-Security-Token")
  valid_605340 = validateParameter(valid_605340, JString, required = false,
                                 default = nil)
  if valid_605340 != nil:
    section.add "X-Amz-Security-Token", valid_605340
  var valid_605341 = header.getOrDefault("X-Amz-Algorithm")
  valid_605341 = validateParameter(valid_605341, JString, required = false,
                                 default = nil)
  if valid_605341 != nil:
    section.add "X-Amz-Algorithm", valid_605341
  var valid_605342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605342 = validateParameter(valid_605342, JString, required = false,
                                 default = nil)
  if valid_605342 != nil:
    section.add "X-Amz-SignedHeaders", valid_605342
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605344: Call_CreateNodegroup_605332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ## 
  let valid = call_605344.validator(path, query, header, formData, body)
  let scheme = call_605344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605344.url(scheme.get, call_605344.host, call_605344.base,
                         call_605344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605344, url, valid)

proc call*(call_605345: Call_CreateNodegroup_605332; name: string; body: JsonNode): Recallable =
  ## createNodegroup
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ##   name: string (required)
  ##       : The name of the cluster to create the node group in.
  ##   body: JObject (required)
  var path_605346 = newJObject()
  var body_605347 = newJObject()
  add(path_605346, "name", newJString(name))
  if body != nil:
    body_605347 = body
  result = call_605345.call(path_605346, nil, nil, nil, body_605347)

var createNodegroup* = Call_CreateNodegroup_605332(name: "createNodegroup",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_CreateNodegroup_605333,
    base: "/", url: url_CreateNodegroup_605334, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodegroups_605315 = ref object of OpenApiRestCall_604659
proc url_ListNodegroups_605317(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListNodegroups_605316(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster that you would like to list node groups in.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605318 = path.getOrDefault("name")
  valid_605318 = validateParameter(valid_605318, JString, required = true,
                                 default = nil)
  if valid_605318 != nil:
    section.add "name", valid_605318
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   maxResults: JInt
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_605319 = query.getOrDefault("nextToken")
  valid_605319 = validateParameter(valid_605319, JString, required = false,
                                 default = nil)
  if valid_605319 != nil:
    section.add "nextToken", valid_605319
  var valid_605320 = query.getOrDefault("maxResults")
  valid_605320 = validateParameter(valid_605320, JInt, required = false, default = nil)
  if valid_605320 != nil:
    section.add "maxResults", valid_605320
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605321 = header.getOrDefault("X-Amz-Signature")
  valid_605321 = validateParameter(valid_605321, JString, required = false,
                                 default = nil)
  if valid_605321 != nil:
    section.add "X-Amz-Signature", valid_605321
  var valid_605322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605322 = validateParameter(valid_605322, JString, required = false,
                                 default = nil)
  if valid_605322 != nil:
    section.add "X-Amz-Content-Sha256", valid_605322
  var valid_605323 = header.getOrDefault("X-Amz-Date")
  valid_605323 = validateParameter(valid_605323, JString, required = false,
                                 default = nil)
  if valid_605323 != nil:
    section.add "X-Amz-Date", valid_605323
  var valid_605324 = header.getOrDefault("X-Amz-Credential")
  valid_605324 = validateParameter(valid_605324, JString, required = false,
                                 default = nil)
  if valid_605324 != nil:
    section.add "X-Amz-Credential", valid_605324
  var valid_605325 = header.getOrDefault("X-Amz-Security-Token")
  valid_605325 = validateParameter(valid_605325, JString, required = false,
                                 default = nil)
  if valid_605325 != nil:
    section.add "X-Amz-Security-Token", valid_605325
  var valid_605326 = header.getOrDefault("X-Amz-Algorithm")
  valid_605326 = validateParameter(valid_605326, JString, required = false,
                                 default = nil)
  if valid_605326 != nil:
    section.add "X-Amz-Algorithm", valid_605326
  var valid_605327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605327 = validateParameter(valid_605327, JString, required = false,
                                 default = nil)
  if valid_605327 != nil:
    section.add "X-Amz-SignedHeaders", valid_605327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605328: Call_ListNodegroups_605315; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ## 
  let valid = call_605328.validator(path, query, header, formData, body)
  let scheme = call_605328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605328.url(scheme.get, call_605328.host, call_605328.base,
                         call_605328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605328, url, valid)

proc call*(call_605329: Call_ListNodegroups_605315; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listNodegroups
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that you would like to list node groups in.
  ##   maxResults: int
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var path_605330 = newJObject()
  var query_605331 = newJObject()
  add(query_605331, "nextToken", newJString(nextToken))
  add(path_605330, "name", newJString(name))
  add(query_605331, "maxResults", newJInt(maxResults))
  result = call_605329.call(path_605330, query_605331, nil, nil, nil)

var listNodegroups* = Call_ListNodegroups_605315(name: "listNodegroups",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_ListNodegroups_605316,
    base: "/", url: url_ListNodegroups_605317, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_605348 = ref object of OpenApiRestCall_604659
proc url_DescribeCluster_605350(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeCluster_605349(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the cluster to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605351 = path.getOrDefault("name")
  valid_605351 = validateParameter(valid_605351, JString, required = true,
                                 default = nil)
  if valid_605351 != nil:
    section.add "name", valid_605351
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605352 = header.getOrDefault("X-Amz-Signature")
  valid_605352 = validateParameter(valid_605352, JString, required = false,
                                 default = nil)
  if valid_605352 != nil:
    section.add "X-Amz-Signature", valid_605352
  var valid_605353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605353 = validateParameter(valid_605353, JString, required = false,
                                 default = nil)
  if valid_605353 != nil:
    section.add "X-Amz-Content-Sha256", valid_605353
  var valid_605354 = header.getOrDefault("X-Amz-Date")
  valid_605354 = validateParameter(valid_605354, JString, required = false,
                                 default = nil)
  if valid_605354 != nil:
    section.add "X-Amz-Date", valid_605354
  var valid_605355 = header.getOrDefault("X-Amz-Credential")
  valid_605355 = validateParameter(valid_605355, JString, required = false,
                                 default = nil)
  if valid_605355 != nil:
    section.add "X-Amz-Credential", valid_605355
  var valid_605356 = header.getOrDefault("X-Amz-Security-Token")
  valid_605356 = validateParameter(valid_605356, JString, required = false,
                                 default = nil)
  if valid_605356 != nil:
    section.add "X-Amz-Security-Token", valid_605356
  var valid_605357 = header.getOrDefault("X-Amz-Algorithm")
  valid_605357 = validateParameter(valid_605357, JString, required = false,
                                 default = nil)
  if valid_605357 != nil:
    section.add "X-Amz-Algorithm", valid_605357
  var valid_605358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605358 = validateParameter(valid_605358, JString, required = false,
                                 default = nil)
  if valid_605358 != nil:
    section.add "X-Amz-SignedHeaders", valid_605358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605359: Call_DescribeCluster_605348; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ## 
  let valid = call_605359.validator(path, query, header, formData, body)
  let scheme = call_605359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605359.url(scheme.get, call_605359.host, call_605359.base,
                         call_605359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605359, url, valid)

proc call*(call_605360: Call_DescribeCluster_605348; name: string): Recallable =
  ## describeCluster
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ##   name: string (required)
  ##       : The name of the cluster to describe.
  var path_605361 = newJObject()
  add(path_605361, "name", newJString(name))
  result = call_605360.call(path_605361, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_605348(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters/{name}",
    validator: validate_DescribeCluster_605349, base: "/", url: url_DescribeCluster_605350,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_605362 = ref object of OpenApiRestCall_604659
proc url_DeleteCluster_605364(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteCluster_605363(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the cluster to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605365 = path.getOrDefault("name")
  valid_605365 = validateParameter(valid_605365, JString, required = true,
                                 default = nil)
  if valid_605365 != nil:
    section.add "name", valid_605365
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605366 = header.getOrDefault("X-Amz-Signature")
  valid_605366 = validateParameter(valid_605366, JString, required = false,
                                 default = nil)
  if valid_605366 != nil:
    section.add "X-Amz-Signature", valid_605366
  var valid_605367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605367 = validateParameter(valid_605367, JString, required = false,
                                 default = nil)
  if valid_605367 != nil:
    section.add "X-Amz-Content-Sha256", valid_605367
  var valid_605368 = header.getOrDefault("X-Amz-Date")
  valid_605368 = validateParameter(valid_605368, JString, required = false,
                                 default = nil)
  if valid_605368 != nil:
    section.add "X-Amz-Date", valid_605368
  var valid_605369 = header.getOrDefault("X-Amz-Credential")
  valid_605369 = validateParameter(valid_605369, JString, required = false,
                                 default = nil)
  if valid_605369 != nil:
    section.add "X-Amz-Credential", valid_605369
  var valid_605370 = header.getOrDefault("X-Amz-Security-Token")
  valid_605370 = validateParameter(valid_605370, JString, required = false,
                                 default = nil)
  if valid_605370 != nil:
    section.add "X-Amz-Security-Token", valid_605370
  var valid_605371 = header.getOrDefault("X-Amz-Algorithm")
  valid_605371 = validateParameter(valid_605371, JString, required = false,
                                 default = nil)
  if valid_605371 != nil:
    section.add "X-Amz-Algorithm", valid_605371
  var valid_605372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605372 = validateParameter(valid_605372, JString, required = false,
                                 default = nil)
  if valid_605372 != nil:
    section.add "X-Amz-SignedHeaders", valid_605372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605373: Call_DeleteCluster_605362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ## 
  let valid = call_605373.validator(path, query, header, formData, body)
  let scheme = call_605373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605373.url(scheme.get, call_605373.host, call_605373.base,
                         call_605373.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605373, url, valid)

proc call*(call_605374: Call_DeleteCluster_605362; name: string): Recallable =
  ## deleteCluster
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ##   name: string (required)
  ##       : The name of the cluster to delete.
  var path_605375 = newJObject()
  add(path_605375, "name", newJString(name))
  result = call_605374.call(path_605375, nil, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_605362(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}", validator: validate_DeleteCluster_605363, base: "/",
    url: url_DeleteCluster_605364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFargateProfile_605376 = ref object of OpenApiRestCall_604659
proc url_DescribeFargateProfile_605378(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeFargateProfile_605377(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns descriptive information about an AWS Fargate profile.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile.
  ##   fargateProfileName: JString (required)
  ##                     : The name of the Fargate profile to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605379 = path.getOrDefault("name")
  valid_605379 = validateParameter(valid_605379, JString, required = true,
                                 default = nil)
  if valid_605379 != nil:
    section.add "name", valid_605379
  var valid_605380 = path.getOrDefault("fargateProfileName")
  valid_605380 = validateParameter(valid_605380, JString, required = true,
                                 default = nil)
  if valid_605380 != nil:
    section.add "fargateProfileName", valid_605380
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605381 = header.getOrDefault("X-Amz-Signature")
  valid_605381 = validateParameter(valid_605381, JString, required = false,
                                 default = nil)
  if valid_605381 != nil:
    section.add "X-Amz-Signature", valid_605381
  var valid_605382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605382 = validateParameter(valid_605382, JString, required = false,
                                 default = nil)
  if valid_605382 != nil:
    section.add "X-Amz-Content-Sha256", valid_605382
  var valid_605383 = header.getOrDefault("X-Amz-Date")
  valid_605383 = validateParameter(valid_605383, JString, required = false,
                                 default = nil)
  if valid_605383 != nil:
    section.add "X-Amz-Date", valid_605383
  var valid_605384 = header.getOrDefault("X-Amz-Credential")
  valid_605384 = validateParameter(valid_605384, JString, required = false,
                                 default = nil)
  if valid_605384 != nil:
    section.add "X-Amz-Credential", valid_605384
  var valid_605385 = header.getOrDefault("X-Amz-Security-Token")
  valid_605385 = validateParameter(valid_605385, JString, required = false,
                                 default = nil)
  if valid_605385 != nil:
    section.add "X-Amz-Security-Token", valid_605385
  var valid_605386 = header.getOrDefault("X-Amz-Algorithm")
  valid_605386 = validateParameter(valid_605386, JString, required = false,
                                 default = nil)
  if valid_605386 != nil:
    section.add "X-Amz-Algorithm", valid_605386
  var valid_605387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605387 = validateParameter(valid_605387, JString, required = false,
                                 default = nil)
  if valid_605387 != nil:
    section.add "X-Amz-SignedHeaders", valid_605387
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605388: Call_DescribeFargateProfile_605376; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptive information about an AWS Fargate profile.
  ## 
  let valid = call_605388.validator(path, query, header, formData, body)
  let scheme = call_605388.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605388.url(scheme.get, call_605388.host, call_605388.base,
                         call_605388.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605388, url, valid)

proc call*(call_605389: Call_DescribeFargateProfile_605376; name: string;
          fargateProfileName: string): Recallable =
  ## describeFargateProfile
  ## Returns descriptive information about an AWS Fargate profile.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile.
  ##   fargateProfileName: string (required)
  ##                     : The name of the Fargate profile to describe.
  var path_605390 = newJObject()
  add(path_605390, "name", newJString(name))
  add(path_605390, "fargateProfileName", newJString(fargateProfileName))
  result = call_605389.call(path_605390, nil, nil, nil, nil)

var describeFargateProfile* = Call_DescribeFargateProfile_605376(
    name: "describeFargateProfile", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DescribeFargateProfile_605377, base: "/",
    url: url_DescribeFargateProfile_605378, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFargateProfile_605391 = ref object of OpenApiRestCall_604659
proc url_DeleteFargateProfile_605393(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFargateProfile_605392(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile to delete.
  ##   fargateProfileName: JString (required)
  ##                     : The name of the Fargate profile to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605394 = path.getOrDefault("name")
  valid_605394 = validateParameter(valid_605394, JString, required = true,
                                 default = nil)
  if valid_605394 != nil:
    section.add "name", valid_605394
  var valid_605395 = path.getOrDefault("fargateProfileName")
  valid_605395 = validateParameter(valid_605395, JString, required = true,
                                 default = nil)
  if valid_605395 != nil:
    section.add "fargateProfileName", valid_605395
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605396 = header.getOrDefault("X-Amz-Signature")
  valid_605396 = validateParameter(valid_605396, JString, required = false,
                                 default = nil)
  if valid_605396 != nil:
    section.add "X-Amz-Signature", valid_605396
  var valid_605397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605397 = validateParameter(valid_605397, JString, required = false,
                                 default = nil)
  if valid_605397 != nil:
    section.add "X-Amz-Content-Sha256", valid_605397
  var valid_605398 = header.getOrDefault("X-Amz-Date")
  valid_605398 = validateParameter(valid_605398, JString, required = false,
                                 default = nil)
  if valid_605398 != nil:
    section.add "X-Amz-Date", valid_605398
  var valid_605399 = header.getOrDefault("X-Amz-Credential")
  valid_605399 = validateParameter(valid_605399, JString, required = false,
                                 default = nil)
  if valid_605399 != nil:
    section.add "X-Amz-Credential", valid_605399
  var valid_605400 = header.getOrDefault("X-Amz-Security-Token")
  valid_605400 = validateParameter(valid_605400, JString, required = false,
                                 default = nil)
  if valid_605400 != nil:
    section.add "X-Amz-Security-Token", valid_605400
  var valid_605401 = header.getOrDefault("X-Amz-Algorithm")
  valid_605401 = validateParameter(valid_605401, JString, required = false,
                                 default = nil)
  if valid_605401 != nil:
    section.add "X-Amz-Algorithm", valid_605401
  var valid_605402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605402 = validateParameter(valid_605402, JString, required = false,
                                 default = nil)
  if valid_605402 != nil:
    section.add "X-Amz-SignedHeaders", valid_605402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605403: Call_DeleteFargateProfile_605391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ## 
  let valid = call_605403.validator(path, query, header, formData, body)
  let scheme = call_605403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605403.url(scheme.get, call_605403.host, call_605403.base,
                         call_605403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605403, url, valid)

proc call*(call_605404: Call_DeleteFargateProfile_605391; name: string;
          fargateProfileName: string): Recallable =
  ## deleteFargateProfile
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile to delete.
  ##   fargateProfileName: string (required)
  ##                     : The name of the Fargate profile to delete.
  var path_605405 = newJObject()
  add(path_605405, "name", newJString(name))
  add(path_605405, "fargateProfileName", newJString(fargateProfileName))
  result = call_605404.call(path_605405, nil, nil, nil, nil)

var deleteFargateProfile* = Call_DeleteFargateProfile_605391(
    name: "deleteFargateProfile", meth: HttpMethod.HttpDelete,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DeleteFargateProfile_605392, base: "/",
    url: url_DeleteFargateProfile_605393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodegroup_605406 = ref object of OpenApiRestCall_604659
proc url_DescribeNodegroup_605408(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeNodegroup_605407(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Returns descriptive information about an Amazon EKS node group.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster associated with the node group.
  ##   nodegroupName: JString (required)
  ##                : The name of the node group to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605409 = path.getOrDefault("name")
  valid_605409 = validateParameter(valid_605409, JString, required = true,
                                 default = nil)
  if valid_605409 != nil:
    section.add "name", valid_605409
  var valid_605410 = path.getOrDefault("nodegroupName")
  valid_605410 = validateParameter(valid_605410, JString, required = true,
                                 default = nil)
  if valid_605410 != nil:
    section.add "nodegroupName", valid_605410
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605411 = header.getOrDefault("X-Amz-Signature")
  valid_605411 = validateParameter(valid_605411, JString, required = false,
                                 default = nil)
  if valid_605411 != nil:
    section.add "X-Amz-Signature", valid_605411
  var valid_605412 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605412 = validateParameter(valid_605412, JString, required = false,
                                 default = nil)
  if valid_605412 != nil:
    section.add "X-Amz-Content-Sha256", valid_605412
  var valid_605413 = header.getOrDefault("X-Amz-Date")
  valid_605413 = validateParameter(valid_605413, JString, required = false,
                                 default = nil)
  if valid_605413 != nil:
    section.add "X-Amz-Date", valid_605413
  var valid_605414 = header.getOrDefault("X-Amz-Credential")
  valid_605414 = validateParameter(valid_605414, JString, required = false,
                                 default = nil)
  if valid_605414 != nil:
    section.add "X-Amz-Credential", valid_605414
  var valid_605415 = header.getOrDefault("X-Amz-Security-Token")
  valid_605415 = validateParameter(valid_605415, JString, required = false,
                                 default = nil)
  if valid_605415 != nil:
    section.add "X-Amz-Security-Token", valid_605415
  var valid_605416 = header.getOrDefault("X-Amz-Algorithm")
  valid_605416 = validateParameter(valid_605416, JString, required = false,
                                 default = nil)
  if valid_605416 != nil:
    section.add "X-Amz-Algorithm", valid_605416
  var valid_605417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605417 = validateParameter(valid_605417, JString, required = false,
                                 default = nil)
  if valid_605417 != nil:
    section.add "X-Amz-SignedHeaders", valid_605417
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605418: Call_DescribeNodegroup_605406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptive information about an Amazon EKS node group.
  ## 
  let valid = call_605418.validator(path, query, header, formData, body)
  let scheme = call_605418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605418.url(scheme.get, call_605418.host, call_605418.base,
                         call_605418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605418, url, valid)

proc call*(call_605419: Call_DescribeNodegroup_605406; name: string;
          nodegroupName: string): Recallable =
  ## describeNodegroup
  ## Returns descriptive information about an Amazon EKS node group.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to describe.
  var path_605420 = newJObject()
  add(path_605420, "name", newJString(name))
  add(path_605420, "nodegroupName", newJString(nodegroupName))
  result = call_605419.call(path_605420, nil, nil, nil, nil)

var describeNodegroup* = Call_DescribeNodegroup_605406(name: "describeNodegroup",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DescribeNodegroup_605407, base: "/",
    url: url_DescribeNodegroup_605408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNodegroup_605421 = ref object of OpenApiRestCall_604659
proc url_DeleteNodegroup_605423(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteNodegroup_605422(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Deletes an Amazon EKS node group for a cluster.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster that is associated with your node group.
  ##   nodegroupName: JString (required)
  ##                : The name of the node group to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605424 = path.getOrDefault("name")
  valid_605424 = validateParameter(valid_605424, JString, required = true,
                                 default = nil)
  if valid_605424 != nil:
    section.add "name", valid_605424
  var valid_605425 = path.getOrDefault("nodegroupName")
  valid_605425 = validateParameter(valid_605425, JString, required = true,
                                 default = nil)
  if valid_605425 != nil:
    section.add "nodegroupName", valid_605425
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605426 = header.getOrDefault("X-Amz-Signature")
  valid_605426 = validateParameter(valid_605426, JString, required = false,
                                 default = nil)
  if valid_605426 != nil:
    section.add "X-Amz-Signature", valid_605426
  var valid_605427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605427 = validateParameter(valid_605427, JString, required = false,
                                 default = nil)
  if valid_605427 != nil:
    section.add "X-Amz-Content-Sha256", valid_605427
  var valid_605428 = header.getOrDefault("X-Amz-Date")
  valid_605428 = validateParameter(valid_605428, JString, required = false,
                                 default = nil)
  if valid_605428 != nil:
    section.add "X-Amz-Date", valid_605428
  var valid_605429 = header.getOrDefault("X-Amz-Credential")
  valid_605429 = validateParameter(valid_605429, JString, required = false,
                                 default = nil)
  if valid_605429 != nil:
    section.add "X-Amz-Credential", valid_605429
  var valid_605430 = header.getOrDefault("X-Amz-Security-Token")
  valid_605430 = validateParameter(valid_605430, JString, required = false,
                                 default = nil)
  if valid_605430 != nil:
    section.add "X-Amz-Security-Token", valid_605430
  var valid_605431 = header.getOrDefault("X-Amz-Algorithm")
  valid_605431 = validateParameter(valid_605431, JString, required = false,
                                 default = nil)
  if valid_605431 != nil:
    section.add "X-Amz-Algorithm", valid_605431
  var valid_605432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605432 = validateParameter(valid_605432, JString, required = false,
                                 default = nil)
  if valid_605432 != nil:
    section.add "X-Amz-SignedHeaders", valid_605432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605433: Call_DeleteNodegroup_605421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon EKS node group for a cluster.
  ## 
  let valid = call_605433.validator(path, query, header, formData, body)
  let scheme = call_605433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605433.url(scheme.get, call_605433.host, call_605433.base,
                         call_605433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605433, url, valid)

proc call*(call_605434: Call_DeleteNodegroup_605421; name: string;
          nodegroupName: string): Recallable =
  ## deleteNodegroup
  ## Deletes an Amazon EKS node group for a cluster.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with your node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to delete.
  var path_605435 = newJObject()
  add(path_605435, "name", newJString(name))
  add(path_605435, "nodegroupName", newJString(nodegroupName))
  result = call_605434.call(path_605435, nil, nil, nil, nil)

var deleteNodegroup* = Call_DeleteNodegroup_605421(name: "deleteNodegroup",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DeleteNodegroup_605422, base: "/", url: url_DeleteNodegroup_605423,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUpdate_605436 = ref object of OpenApiRestCall_604659
proc url_DescribeUpdate_605438(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeUpdate_605437(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   updateId: JString (required)
  ##           : The ID of the update to describe.
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster associated with the update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `updateId` field"
  var valid_605439 = path.getOrDefault("updateId")
  valid_605439 = validateParameter(valid_605439, JString, required = true,
                                 default = nil)
  if valid_605439 != nil:
    section.add "updateId", valid_605439
  var valid_605440 = path.getOrDefault("name")
  valid_605440 = validateParameter(valid_605440, JString, required = true,
                                 default = nil)
  if valid_605440 != nil:
    section.add "name", valid_605440
  result.add "path", section
  ## parameters in `query` object:
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS node group associated with the update.
  section = newJObject()
  var valid_605441 = query.getOrDefault("nodegroupName")
  valid_605441 = validateParameter(valid_605441, JString, required = false,
                                 default = nil)
  if valid_605441 != nil:
    section.add "nodegroupName", valid_605441
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605442 = header.getOrDefault("X-Amz-Signature")
  valid_605442 = validateParameter(valid_605442, JString, required = false,
                                 default = nil)
  if valid_605442 != nil:
    section.add "X-Amz-Signature", valid_605442
  var valid_605443 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605443 = validateParameter(valid_605443, JString, required = false,
                                 default = nil)
  if valid_605443 != nil:
    section.add "X-Amz-Content-Sha256", valid_605443
  var valid_605444 = header.getOrDefault("X-Amz-Date")
  valid_605444 = validateParameter(valid_605444, JString, required = false,
                                 default = nil)
  if valid_605444 != nil:
    section.add "X-Amz-Date", valid_605444
  var valid_605445 = header.getOrDefault("X-Amz-Credential")
  valid_605445 = validateParameter(valid_605445, JString, required = false,
                                 default = nil)
  if valid_605445 != nil:
    section.add "X-Amz-Credential", valid_605445
  var valid_605446 = header.getOrDefault("X-Amz-Security-Token")
  valid_605446 = validateParameter(valid_605446, JString, required = false,
                                 default = nil)
  if valid_605446 != nil:
    section.add "X-Amz-Security-Token", valid_605446
  var valid_605447 = header.getOrDefault("X-Amz-Algorithm")
  valid_605447 = validateParameter(valid_605447, JString, required = false,
                                 default = nil)
  if valid_605447 != nil:
    section.add "X-Amz-Algorithm", valid_605447
  var valid_605448 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605448 = validateParameter(valid_605448, JString, required = false,
                                 default = nil)
  if valid_605448 != nil:
    section.add "X-Amz-SignedHeaders", valid_605448
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605449: Call_DescribeUpdate_605436; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ## 
  let valid = call_605449.validator(path, query, header, formData, body)
  let scheme = call_605449.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605449.url(scheme.get, call_605449.host, call_605449.base,
                         call_605449.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605449, url, valid)

proc call*(call_605450: Call_DescribeUpdate_605436; updateId: string; name: string;
          nodegroupName: string = ""): Recallable =
  ## describeUpdate
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ##   updateId: string (required)
  ##           : The ID of the update to describe.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the update.
  ##   nodegroupName: string
  ##                : The name of the Amazon EKS node group associated with the update.
  var path_605451 = newJObject()
  var query_605452 = newJObject()
  add(path_605451, "updateId", newJString(updateId))
  add(path_605451, "name", newJString(name))
  add(query_605452, "nodegroupName", newJString(nodegroupName))
  result = call_605450.call(path_605451, query_605452, nil, nil, nil)

var describeUpdate* = Call_DescribeUpdate_605436(name: "describeUpdate",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/updates/{updateId}",
    validator: validate_DescribeUpdate_605437, base: "/", url: url_DescribeUpdate_605438,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_605467 = ref object of OpenApiRestCall_604659
proc url_TagResource_605469(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_605468(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_605470 = path.getOrDefault("resourceArn")
  valid_605470 = validateParameter(valid_605470, JString, required = true,
                                 default = nil)
  if valid_605470 != nil:
    section.add "resourceArn", valid_605470
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605471 = header.getOrDefault("X-Amz-Signature")
  valid_605471 = validateParameter(valid_605471, JString, required = false,
                                 default = nil)
  if valid_605471 != nil:
    section.add "X-Amz-Signature", valid_605471
  var valid_605472 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605472 = validateParameter(valid_605472, JString, required = false,
                                 default = nil)
  if valid_605472 != nil:
    section.add "X-Amz-Content-Sha256", valid_605472
  var valid_605473 = header.getOrDefault("X-Amz-Date")
  valid_605473 = validateParameter(valid_605473, JString, required = false,
                                 default = nil)
  if valid_605473 != nil:
    section.add "X-Amz-Date", valid_605473
  var valid_605474 = header.getOrDefault("X-Amz-Credential")
  valid_605474 = validateParameter(valid_605474, JString, required = false,
                                 default = nil)
  if valid_605474 != nil:
    section.add "X-Amz-Credential", valid_605474
  var valid_605475 = header.getOrDefault("X-Amz-Security-Token")
  valid_605475 = validateParameter(valid_605475, JString, required = false,
                                 default = nil)
  if valid_605475 != nil:
    section.add "X-Amz-Security-Token", valid_605475
  var valid_605476 = header.getOrDefault("X-Amz-Algorithm")
  valid_605476 = validateParameter(valid_605476, JString, required = false,
                                 default = nil)
  if valid_605476 != nil:
    section.add "X-Amz-Algorithm", valid_605476
  var valid_605477 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605477 = validateParameter(valid_605477, JString, required = false,
                                 default = nil)
  if valid_605477 != nil:
    section.add "X-Amz-SignedHeaders", valid_605477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605479: Call_TagResource_605467; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ## 
  let valid = call_605479.validator(path, query, header, formData, body)
  let scheme = call_605479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605479.url(scheme.get, call_605479.host, call_605479.base,
                         call_605479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605479, url, valid)

proc call*(call_605480: Call_TagResource_605467; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to which to add tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  ##   body: JObject (required)
  var path_605481 = newJObject()
  var body_605482 = newJObject()
  add(path_605481, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_605482 = body
  result = call_605480.call(path_605481, nil, nil, nil, body_605482)

var tagResource* = Call_TagResource_605467(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "eks.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_605468,
                                        base: "/", url: url_TagResource_605469,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_605453 = ref object of OpenApiRestCall_604659
proc url_ListTagsForResource_605455(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_605454(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_605456 = path.getOrDefault("resourceArn")
  valid_605456 = validateParameter(valid_605456, JString, required = true,
                                 default = nil)
  if valid_605456 != nil:
    section.add "resourceArn", valid_605456
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605457 = header.getOrDefault("X-Amz-Signature")
  valid_605457 = validateParameter(valid_605457, JString, required = false,
                                 default = nil)
  if valid_605457 != nil:
    section.add "X-Amz-Signature", valid_605457
  var valid_605458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605458 = validateParameter(valid_605458, JString, required = false,
                                 default = nil)
  if valid_605458 != nil:
    section.add "X-Amz-Content-Sha256", valid_605458
  var valid_605459 = header.getOrDefault("X-Amz-Date")
  valid_605459 = validateParameter(valid_605459, JString, required = false,
                                 default = nil)
  if valid_605459 != nil:
    section.add "X-Amz-Date", valid_605459
  var valid_605460 = header.getOrDefault("X-Amz-Credential")
  valid_605460 = validateParameter(valid_605460, JString, required = false,
                                 default = nil)
  if valid_605460 != nil:
    section.add "X-Amz-Credential", valid_605460
  var valid_605461 = header.getOrDefault("X-Amz-Security-Token")
  valid_605461 = validateParameter(valid_605461, JString, required = false,
                                 default = nil)
  if valid_605461 != nil:
    section.add "X-Amz-Security-Token", valid_605461
  var valid_605462 = header.getOrDefault("X-Amz-Algorithm")
  valid_605462 = validateParameter(valid_605462, JString, required = false,
                                 default = nil)
  if valid_605462 != nil:
    section.add "X-Amz-Algorithm", valid_605462
  var valid_605463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605463 = validateParameter(valid_605463, JString, required = false,
                                 default = nil)
  if valid_605463 != nil:
    section.add "X-Amz-SignedHeaders", valid_605463
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605464: Call_ListTagsForResource_605453; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon EKS resource.
  ## 
  let valid = call_605464.validator(path, query, header, formData, body)
  let scheme = call_605464.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605464.url(scheme.get, call_605464.host, call_605464.base,
                         call_605464.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605464, url, valid)

proc call*(call_605465: Call_ListTagsForResource_605453; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon EKS resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_605466 = newJObject()
  add(path_605466, "resourceArn", newJString(resourceArn))
  result = call_605465.call(path_605466, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_605453(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_605454, base: "/",
    url: url_ListTagsForResource_605455, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterVersion_605501 = ref object of OpenApiRestCall_604659
proc url_UpdateClusterVersion_605503(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateClusterVersion_605502(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605504 = path.getOrDefault("name")
  valid_605504 = validateParameter(valid_605504, JString, required = true,
                                 default = nil)
  if valid_605504 != nil:
    section.add "name", valid_605504
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605505 = header.getOrDefault("X-Amz-Signature")
  valid_605505 = validateParameter(valid_605505, JString, required = false,
                                 default = nil)
  if valid_605505 != nil:
    section.add "X-Amz-Signature", valid_605505
  var valid_605506 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605506 = validateParameter(valid_605506, JString, required = false,
                                 default = nil)
  if valid_605506 != nil:
    section.add "X-Amz-Content-Sha256", valid_605506
  var valid_605507 = header.getOrDefault("X-Amz-Date")
  valid_605507 = validateParameter(valid_605507, JString, required = false,
                                 default = nil)
  if valid_605507 != nil:
    section.add "X-Amz-Date", valid_605507
  var valid_605508 = header.getOrDefault("X-Amz-Credential")
  valid_605508 = validateParameter(valid_605508, JString, required = false,
                                 default = nil)
  if valid_605508 != nil:
    section.add "X-Amz-Credential", valid_605508
  var valid_605509 = header.getOrDefault("X-Amz-Security-Token")
  valid_605509 = validateParameter(valid_605509, JString, required = false,
                                 default = nil)
  if valid_605509 != nil:
    section.add "X-Amz-Security-Token", valid_605509
  var valid_605510 = header.getOrDefault("X-Amz-Algorithm")
  valid_605510 = validateParameter(valid_605510, JString, required = false,
                                 default = nil)
  if valid_605510 != nil:
    section.add "X-Amz-Algorithm", valid_605510
  var valid_605511 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605511 = validateParameter(valid_605511, JString, required = false,
                                 default = nil)
  if valid_605511 != nil:
    section.add "X-Amz-SignedHeaders", valid_605511
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605513: Call_UpdateClusterVersion_605501; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ## 
  let valid = call_605513.validator(path, query, header, formData, body)
  let scheme = call_605513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605513.url(scheme.get, call_605513.host, call_605513.base,
                         call_605513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605513, url, valid)

proc call*(call_605514: Call_UpdateClusterVersion_605501; name: string;
          body: JsonNode): Recallable =
  ## updateClusterVersion
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_605515 = newJObject()
  var body_605516 = newJObject()
  add(path_605515, "name", newJString(name))
  if body != nil:
    body_605516 = body
  result = call_605514.call(path_605515, nil, nil, nil, body_605516)

var updateClusterVersion* = Call_UpdateClusterVersion_605501(
    name: "updateClusterVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/updates",
    validator: validate_UpdateClusterVersion_605502, base: "/",
    url: url_UpdateClusterVersion_605503, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUpdates_605483 = ref object of OpenApiRestCall_604659
proc url_ListUpdates_605485(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListUpdates_605484(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster to list updates for.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605486 = path.getOrDefault("name")
  valid_605486 = validateParameter(valid_605486, JString, required = true,
                                 default = nil)
  if valid_605486 != nil:
    section.add "name", valid_605486
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListUpdates</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS managed node group to list updates for.
  ##   maxResults: JInt
  ##             : The maximum number of update results returned by <code>ListUpdates</code> in paginated output. When you use this parameter, <code>ListUpdates</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListUpdates</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListUpdates</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_605487 = query.getOrDefault("nextToken")
  valid_605487 = validateParameter(valid_605487, JString, required = false,
                                 default = nil)
  if valid_605487 != nil:
    section.add "nextToken", valid_605487
  var valid_605488 = query.getOrDefault("nodegroupName")
  valid_605488 = validateParameter(valid_605488, JString, required = false,
                                 default = nil)
  if valid_605488 != nil:
    section.add "nodegroupName", valid_605488
  var valid_605489 = query.getOrDefault("maxResults")
  valid_605489 = validateParameter(valid_605489, JInt, required = false, default = nil)
  if valid_605489 != nil:
    section.add "maxResults", valid_605489
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605490 = header.getOrDefault("X-Amz-Signature")
  valid_605490 = validateParameter(valid_605490, JString, required = false,
                                 default = nil)
  if valid_605490 != nil:
    section.add "X-Amz-Signature", valid_605490
  var valid_605491 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605491 = validateParameter(valid_605491, JString, required = false,
                                 default = nil)
  if valid_605491 != nil:
    section.add "X-Amz-Content-Sha256", valid_605491
  var valid_605492 = header.getOrDefault("X-Amz-Date")
  valid_605492 = validateParameter(valid_605492, JString, required = false,
                                 default = nil)
  if valid_605492 != nil:
    section.add "X-Amz-Date", valid_605492
  var valid_605493 = header.getOrDefault("X-Amz-Credential")
  valid_605493 = validateParameter(valid_605493, JString, required = false,
                                 default = nil)
  if valid_605493 != nil:
    section.add "X-Amz-Credential", valid_605493
  var valid_605494 = header.getOrDefault("X-Amz-Security-Token")
  valid_605494 = validateParameter(valid_605494, JString, required = false,
                                 default = nil)
  if valid_605494 != nil:
    section.add "X-Amz-Security-Token", valid_605494
  var valid_605495 = header.getOrDefault("X-Amz-Algorithm")
  valid_605495 = validateParameter(valid_605495, JString, required = false,
                                 default = nil)
  if valid_605495 != nil:
    section.add "X-Amz-Algorithm", valid_605495
  var valid_605496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605496 = validateParameter(valid_605496, JString, required = false,
                                 default = nil)
  if valid_605496 != nil:
    section.add "X-Amz-SignedHeaders", valid_605496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605497: Call_ListUpdates_605483; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
  ## 
  let valid = call_605497.validator(path, query, header, formData, body)
  let scheme = call_605497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605497.url(scheme.get, call_605497.host, call_605497.base,
                         call_605497.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605497, url, valid)

proc call*(call_605498: Call_ListUpdates_605483; name: string;
          nextToken: string = ""; nodegroupName: string = ""; maxResults: int = 0): Recallable =
  ## listUpdates
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListUpdates</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to list updates for.
  ##   nodegroupName: string
  ##                : The name of the Amazon EKS managed node group to list updates for.
  ##   maxResults: int
  ##             : The maximum number of update results returned by <code>ListUpdates</code> in paginated output. When you use this parameter, <code>ListUpdates</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListUpdates</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListUpdates</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var path_605499 = newJObject()
  var query_605500 = newJObject()
  add(query_605500, "nextToken", newJString(nextToken))
  add(path_605499, "name", newJString(name))
  add(query_605500, "nodegroupName", newJString(nodegroupName))
  add(query_605500, "maxResults", newJInt(maxResults))
  result = call_605498.call(path_605499, query_605500, nil, nil, nil)

var listUpdates* = Call_ListUpdates_605483(name: "listUpdates",
                                        meth: HttpMethod.HttpGet,
                                        host: "eks.amazonaws.com",
                                        route: "/clusters/{name}/updates",
                                        validator: validate_ListUpdates_605484,
                                        base: "/", url: url_ListUpdates_605485,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_605517 = ref object of OpenApiRestCall_604659
proc url_UntagResource_605519(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_605518(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_605520 = path.getOrDefault("resourceArn")
  valid_605520 = validateParameter(valid_605520, JString, required = true,
                                 default = nil)
  if valid_605520 != nil:
    section.add "resourceArn", valid_605520
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_605521 = query.getOrDefault("tagKeys")
  valid_605521 = validateParameter(valid_605521, JArray, required = true, default = nil)
  if valid_605521 != nil:
    section.add "tagKeys", valid_605521
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605522 = header.getOrDefault("X-Amz-Signature")
  valid_605522 = validateParameter(valid_605522, JString, required = false,
                                 default = nil)
  if valid_605522 != nil:
    section.add "X-Amz-Signature", valid_605522
  var valid_605523 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605523 = validateParameter(valid_605523, JString, required = false,
                                 default = nil)
  if valid_605523 != nil:
    section.add "X-Amz-Content-Sha256", valid_605523
  var valid_605524 = header.getOrDefault("X-Amz-Date")
  valid_605524 = validateParameter(valid_605524, JString, required = false,
                                 default = nil)
  if valid_605524 != nil:
    section.add "X-Amz-Date", valid_605524
  var valid_605525 = header.getOrDefault("X-Amz-Credential")
  valid_605525 = validateParameter(valid_605525, JString, required = false,
                                 default = nil)
  if valid_605525 != nil:
    section.add "X-Amz-Credential", valid_605525
  var valid_605526 = header.getOrDefault("X-Amz-Security-Token")
  valid_605526 = validateParameter(valid_605526, JString, required = false,
                                 default = nil)
  if valid_605526 != nil:
    section.add "X-Amz-Security-Token", valid_605526
  var valid_605527 = header.getOrDefault("X-Amz-Algorithm")
  valid_605527 = validateParameter(valid_605527, JString, required = false,
                                 default = nil)
  if valid_605527 != nil:
    section.add "X-Amz-Algorithm", valid_605527
  var valid_605528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605528 = validateParameter(valid_605528, JString, required = false,
                                 default = nil)
  if valid_605528 != nil:
    section.add "X-Amz-SignedHeaders", valid_605528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_605529: Call_UntagResource_605517; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_605529.validator(path, query, header, formData, body)
  let scheme = call_605529.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605529.url(scheme.get, call_605529.host, call_605529.base,
                         call_605529.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605529, url, valid)

proc call*(call_605530: Call_UntagResource_605517; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource from which to delete tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  var path_605531 = newJObject()
  var query_605532 = newJObject()
  add(path_605531, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_605532.add "tagKeys", tagKeys
  result = call_605530.call(path_605531, query_605532, nil, nil, nil)

var untagResource* = Call_UntagResource_605517(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_605518,
    base: "/", url: url_UntagResource_605519, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfig_605533 = ref object of OpenApiRestCall_604659
proc url_UpdateClusterConfig_605535(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateClusterConfig_605534(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605536 = path.getOrDefault("name")
  valid_605536 = validateParameter(valid_605536, JString, required = true,
                                 default = nil)
  if valid_605536 != nil:
    section.add "name", valid_605536
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605537 = header.getOrDefault("X-Amz-Signature")
  valid_605537 = validateParameter(valid_605537, JString, required = false,
                                 default = nil)
  if valid_605537 != nil:
    section.add "X-Amz-Signature", valid_605537
  var valid_605538 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605538 = validateParameter(valid_605538, JString, required = false,
                                 default = nil)
  if valid_605538 != nil:
    section.add "X-Amz-Content-Sha256", valid_605538
  var valid_605539 = header.getOrDefault("X-Amz-Date")
  valid_605539 = validateParameter(valid_605539, JString, required = false,
                                 default = nil)
  if valid_605539 != nil:
    section.add "X-Amz-Date", valid_605539
  var valid_605540 = header.getOrDefault("X-Amz-Credential")
  valid_605540 = validateParameter(valid_605540, JString, required = false,
                                 default = nil)
  if valid_605540 != nil:
    section.add "X-Amz-Credential", valid_605540
  var valid_605541 = header.getOrDefault("X-Amz-Security-Token")
  valid_605541 = validateParameter(valid_605541, JString, required = false,
                                 default = nil)
  if valid_605541 != nil:
    section.add "X-Amz-Security-Token", valid_605541
  var valid_605542 = header.getOrDefault("X-Amz-Algorithm")
  valid_605542 = validateParameter(valid_605542, JString, required = false,
                                 default = nil)
  if valid_605542 != nil:
    section.add "X-Amz-Algorithm", valid_605542
  var valid_605543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605543 = validateParameter(valid_605543, JString, required = false,
                                 default = nil)
  if valid_605543 != nil:
    section.add "X-Amz-SignedHeaders", valid_605543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605545: Call_UpdateClusterConfig_605533; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ## 
  let valid = call_605545.validator(path, query, header, formData, body)
  let scheme = call_605545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605545.url(scheme.get, call_605545.host, call_605545.base,
                         call_605545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605545, url, valid)

proc call*(call_605546: Call_UpdateClusterConfig_605533; name: string; body: JsonNode): Recallable =
  ## updateClusterConfig
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_605547 = newJObject()
  var body_605548 = newJObject()
  add(path_605547, "name", newJString(name))
  if body != nil:
    body_605548 = body
  result = call_605546.call(path_605547, nil, nil, nil, body_605548)

var updateClusterConfig* = Call_UpdateClusterConfig_605533(
    name: "updateClusterConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/update-config",
    validator: validate_UpdateClusterConfig_605534, base: "/",
    url: url_UpdateClusterConfig_605535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupConfig_605549 = ref object of OpenApiRestCall_604659
proc url_UpdateNodegroupConfig_605551(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateNodegroupConfig_605550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster that the managed node group resides in.
  ##   nodegroupName: JString (required)
  ##                : The name of the managed node group to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605552 = path.getOrDefault("name")
  valid_605552 = validateParameter(valid_605552, JString, required = true,
                                 default = nil)
  if valid_605552 != nil:
    section.add "name", valid_605552
  var valid_605553 = path.getOrDefault("nodegroupName")
  valid_605553 = validateParameter(valid_605553, JString, required = true,
                                 default = nil)
  if valid_605553 != nil:
    section.add "nodegroupName", valid_605553
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605554 = header.getOrDefault("X-Amz-Signature")
  valid_605554 = validateParameter(valid_605554, JString, required = false,
                                 default = nil)
  if valid_605554 != nil:
    section.add "X-Amz-Signature", valid_605554
  var valid_605555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605555 = validateParameter(valid_605555, JString, required = false,
                                 default = nil)
  if valid_605555 != nil:
    section.add "X-Amz-Content-Sha256", valid_605555
  var valid_605556 = header.getOrDefault("X-Amz-Date")
  valid_605556 = validateParameter(valid_605556, JString, required = false,
                                 default = nil)
  if valid_605556 != nil:
    section.add "X-Amz-Date", valid_605556
  var valid_605557 = header.getOrDefault("X-Amz-Credential")
  valid_605557 = validateParameter(valid_605557, JString, required = false,
                                 default = nil)
  if valid_605557 != nil:
    section.add "X-Amz-Credential", valid_605557
  var valid_605558 = header.getOrDefault("X-Amz-Security-Token")
  valid_605558 = validateParameter(valid_605558, JString, required = false,
                                 default = nil)
  if valid_605558 != nil:
    section.add "X-Amz-Security-Token", valid_605558
  var valid_605559 = header.getOrDefault("X-Amz-Algorithm")
  valid_605559 = validateParameter(valid_605559, JString, required = false,
                                 default = nil)
  if valid_605559 != nil:
    section.add "X-Amz-Algorithm", valid_605559
  var valid_605560 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605560 = validateParameter(valid_605560, JString, required = false,
                                 default = nil)
  if valid_605560 != nil:
    section.add "X-Amz-SignedHeaders", valid_605560
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605562: Call_UpdateNodegroupConfig_605549; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ## 
  let valid = call_605562.validator(path, query, header, formData, body)
  let scheme = call_605562.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605562.url(scheme.get, call_605562.host, call_605562.base,
                         call_605562.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605562, url, valid)

proc call*(call_605563: Call_UpdateNodegroupConfig_605549; name: string;
          body: JsonNode; nodegroupName: string): Recallable =
  ## updateNodegroupConfig
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that the managed node group resides in.
  ##   body: JObject (required)
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  var path_605564 = newJObject()
  var body_605565 = newJObject()
  add(path_605564, "name", newJString(name))
  if body != nil:
    body_605565 = body
  add(path_605564, "nodegroupName", newJString(nodegroupName))
  result = call_605563.call(path_605564, nil, nil, nil, body_605565)

var updateNodegroupConfig* = Call_UpdateNodegroupConfig_605549(
    name: "updateNodegroupConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-config",
    validator: validate_UpdateNodegroupConfig_605550, base: "/",
    url: url_UpdateNodegroupConfig_605551, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupVersion_605566 = ref object of OpenApiRestCall_604659
proc url_UpdateNodegroupVersion_605568(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateNodegroupVersion_605567(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster that is associated with the managed node group to update.
  ##   nodegroupName: JString (required)
  ##                : The name of the managed node group to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_605569 = path.getOrDefault("name")
  valid_605569 = validateParameter(valid_605569, JString, required = true,
                                 default = nil)
  if valid_605569 != nil:
    section.add "name", valid_605569
  var valid_605570 = path.getOrDefault("nodegroupName")
  valid_605570 = validateParameter(valid_605570, JString, required = true,
                                 default = nil)
  if valid_605570 != nil:
    section.add "nodegroupName", valid_605570
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_605571 = header.getOrDefault("X-Amz-Signature")
  valid_605571 = validateParameter(valid_605571, JString, required = false,
                                 default = nil)
  if valid_605571 != nil:
    section.add "X-Amz-Signature", valid_605571
  var valid_605572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_605572 = validateParameter(valid_605572, JString, required = false,
                                 default = nil)
  if valid_605572 != nil:
    section.add "X-Amz-Content-Sha256", valid_605572
  var valid_605573 = header.getOrDefault("X-Amz-Date")
  valid_605573 = validateParameter(valid_605573, JString, required = false,
                                 default = nil)
  if valid_605573 != nil:
    section.add "X-Amz-Date", valid_605573
  var valid_605574 = header.getOrDefault("X-Amz-Credential")
  valid_605574 = validateParameter(valid_605574, JString, required = false,
                                 default = nil)
  if valid_605574 != nil:
    section.add "X-Amz-Credential", valid_605574
  var valid_605575 = header.getOrDefault("X-Amz-Security-Token")
  valid_605575 = validateParameter(valid_605575, JString, required = false,
                                 default = nil)
  if valid_605575 != nil:
    section.add "X-Amz-Security-Token", valid_605575
  var valid_605576 = header.getOrDefault("X-Amz-Algorithm")
  valid_605576 = validateParameter(valid_605576, JString, required = false,
                                 default = nil)
  if valid_605576 != nil:
    section.add "X-Amz-Algorithm", valid_605576
  var valid_605577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_605577 = validateParameter(valid_605577, JString, required = false,
                                 default = nil)
  if valid_605577 != nil:
    section.add "X-Amz-SignedHeaders", valid_605577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_605579: Call_UpdateNodegroupVersion_605566; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ## 
  let valid = call_605579.validator(path, query, header, formData, body)
  let scheme = call_605579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_605579.url(scheme.get, call_605579.host, call_605579.base,
                         call_605579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_605579, url, valid)

proc call*(call_605580: Call_UpdateNodegroupVersion_605566; name: string;
          body: JsonNode; nodegroupName: string): Recallable =
  ## updateNodegroupVersion
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with the managed node group to update.
  ##   body: JObject (required)
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  var path_605581 = newJObject()
  var body_605582 = newJObject()
  add(path_605581, "name", newJString(name))
  if body != nil:
    body_605582 = body
  add(path_605581, "nodegroupName", newJString(nodegroupName))
  result = call_605580.call(path_605581, nil, nil, nil, body_605582)

var updateNodegroupVersion* = Call_UpdateNodegroupVersion_605566(
    name: "updateNodegroupVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-version",
    validator: validate_UpdateNodegroupVersion_605567, base: "/",
    url: url_UpdateNodegroupVersion_605568, schemes: {Scheme.Https, Scheme.Http})
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
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
