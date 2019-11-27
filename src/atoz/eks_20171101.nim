
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

  OpenApiRestCall_599369 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599369](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599369): Option[Scheme] {.used.} =
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
  Call_CreateCluster_599963 = ref object of OpenApiRestCall_599369
proc url_CreateCluster_599965(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_599964(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599966 = header.getOrDefault("X-Amz-Date")
  valid_599966 = validateParameter(valid_599966, JString, required = false,
                                 default = nil)
  if valid_599966 != nil:
    section.add "X-Amz-Date", valid_599966
  var valid_599967 = header.getOrDefault("X-Amz-Security-Token")
  valid_599967 = validateParameter(valid_599967, JString, required = false,
                                 default = nil)
  if valid_599967 != nil:
    section.add "X-Amz-Security-Token", valid_599967
  var valid_599968 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599968 = validateParameter(valid_599968, JString, required = false,
                                 default = nil)
  if valid_599968 != nil:
    section.add "X-Amz-Content-Sha256", valid_599968
  var valid_599969 = header.getOrDefault("X-Amz-Algorithm")
  valid_599969 = validateParameter(valid_599969, JString, required = false,
                                 default = nil)
  if valid_599969 != nil:
    section.add "X-Amz-Algorithm", valid_599969
  var valid_599970 = header.getOrDefault("X-Amz-Signature")
  valid_599970 = validateParameter(valid_599970, JString, required = false,
                                 default = nil)
  if valid_599970 != nil:
    section.add "X-Amz-Signature", valid_599970
  var valid_599971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599971 = validateParameter(valid_599971, JString, required = false,
                                 default = nil)
  if valid_599971 != nil:
    section.add "X-Amz-SignedHeaders", valid_599971
  var valid_599972 = header.getOrDefault("X-Amz-Credential")
  valid_599972 = validateParameter(valid_599972, JString, required = false,
                                 default = nil)
  if valid_599972 != nil:
    section.add "X-Amz-Credential", valid_599972
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599974: Call_CreateCluster_599963; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  let valid = call_599974.validator(path, query, header, formData, body)
  let scheme = call_599974.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599974.url(scheme.get, call_599974.host, call_599974.base,
                         call_599974.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599974, url, valid)

proc call*(call_599975: Call_CreateCluster_599963; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   body: JObject (required)
  var body_599976 = newJObject()
  if body != nil:
    body_599976 = body
  result = call_599975.call(nil, nil, nil, nil, body_599976)

var createCluster* = Call_CreateCluster_599963(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_CreateCluster_599964, base: "/", url: url_CreateCluster_599965,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_599706 = ref object of OpenApiRestCall_599369
proc url_ListClusters_599708(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListClusters_599707(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of cluster results returned by <code>ListClusters</code> in paginated output. When you use this parameter, <code>ListClusters</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListClusters</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListClusters</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: JString
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListClusters</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.</p> <note> <p>This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  section = newJObject()
  var valid_599820 = query.getOrDefault("maxResults")
  valid_599820 = validateParameter(valid_599820, JInt, required = false, default = nil)
  if valid_599820 != nil:
    section.add "maxResults", valid_599820
  var valid_599821 = query.getOrDefault("nextToken")
  valid_599821 = validateParameter(valid_599821, JString, required = false,
                                 default = nil)
  if valid_599821 != nil:
    section.add "nextToken", valid_599821
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599822 = header.getOrDefault("X-Amz-Date")
  valid_599822 = validateParameter(valid_599822, JString, required = false,
                                 default = nil)
  if valid_599822 != nil:
    section.add "X-Amz-Date", valid_599822
  var valid_599823 = header.getOrDefault("X-Amz-Security-Token")
  valid_599823 = validateParameter(valid_599823, JString, required = false,
                                 default = nil)
  if valid_599823 != nil:
    section.add "X-Amz-Security-Token", valid_599823
  var valid_599824 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599824 = validateParameter(valid_599824, JString, required = false,
                                 default = nil)
  if valid_599824 != nil:
    section.add "X-Amz-Content-Sha256", valid_599824
  var valid_599825 = header.getOrDefault("X-Amz-Algorithm")
  valid_599825 = validateParameter(valid_599825, JString, required = false,
                                 default = nil)
  if valid_599825 != nil:
    section.add "X-Amz-Algorithm", valid_599825
  var valid_599826 = header.getOrDefault("X-Amz-Signature")
  valid_599826 = validateParameter(valid_599826, JString, required = false,
                                 default = nil)
  if valid_599826 != nil:
    section.add "X-Amz-Signature", valid_599826
  var valid_599827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599827 = validateParameter(valid_599827, JString, required = false,
                                 default = nil)
  if valid_599827 != nil:
    section.add "X-Amz-SignedHeaders", valid_599827
  var valid_599828 = header.getOrDefault("X-Amz-Credential")
  valid_599828 = validateParameter(valid_599828, JString, required = false,
                                 default = nil)
  if valid_599828 != nil:
    section.add "X-Amz-Credential", valid_599828
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599851: Call_ListClusters_599706; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ## 
  let valid = call_599851.validator(path, query, header, formData, body)
  let scheme = call_599851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599851.url(scheme.get, call_599851.host, call_599851.base,
                         call_599851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599851, url, valid)

proc call*(call_599922: Call_ListClusters_599706; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listClusters
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ##   maxResults: int
  ##             : The maximum number of cluster results returned by <code>ListClusters</code> in paginated output. When you use this parameter, <code>ListClusters</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListClusters</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListClusters</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListClusters</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.</p> <note> <p>This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  var query_599923 = newJObject()
  add(query_599923, "maxResults", newJInt(maxResults))
  add(query_599923, "nextToken", newJString(nextToken))
  result = call_599922.call(nil, query_599923, nil, nil, nil)

var listClusters* = Call_ListClusters_599706(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_ListClusters_599707, base: "/", url: url_ListClusters_599708,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNodegroup_600008 = ref object of OpenApiRestCall_599369
proc url_CreateNodegroup_600010(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNodegroup_600009(path: JsonNode; query: JsonNode;
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
  var valid_600011 = path.getOrDefault("name")
  valid_600011 = validateParameter(valid_600011, JString, required = true,
                                 default = nil)
  if valid_600011 != nil:
    section.add "name", valid_600011
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600012 = header.getOrDefault("X-Amz-Date")
  valid_600012 = validateParameter(valid_600012, JString, required = false,
                                 default = nil)
  if valid_600012 != nil:
    section.add "X-Amz-Date", valid_600012
  var valid_600013 = header.getOrDefault("X-Amz-Security-Token")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "X-Amz-Security-Token", valid_600013
  var valid_600014 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600014 = validateParameter(valid_600014, JString, required = false,
                                 default = nil)
  if valid_600014 != nil:
    section.add "X-Amz-Content-Sha256", valid_600014
  var valid_600015 = header.getOrDefault("X-Amz-Algorithm")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "X-Amz-Algorithm", valid_600015
  var valid_600016 = header.getOrDefault("X-Amz-Signature")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "X-Amz-Signature", valid_600016
  var valid_600017 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-SignedHeaders", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Credential")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Credential", valid_600018
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600020: Call_CreateNodegroup_600008; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ## 
  let valid = call_600020.validator(path, query, header, formData, body)
  let scheme = call_600020.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600020.url(scheme.get, call_600020.host, call_600020.base,
                         call_600020.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600020, url, valid)

proc call*(call_600021: Call_CreateNodegroup_600008; name: string; body: JsonNode): Recallable =
  ## createNodegroup
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ##   name: string (required)
  ##       : The name of the cluster to create the node group in.
  ##   body: JObject (required)
  var path_600022 = newJObject()
  var body_600023 = newJObject()
  add(path_600022, "name", newJString(name))
  if body != nil:
    body_600023 = body
  result = call_600021.call(path_600022, nil, nil, nil, body_600023)

var createNodegroup* = Call_CreateNodegroup_600008(name: "createNodegroup",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_CreateNodegroup_600009,
    base: "/", url: url_CreateNodegroup_600010, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodegroups_599977 = ref object of OpenApiRestCall_599369
proc url_ListNodegroups_599979(protocol: Scheme; host: string; base: string;
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

proc validate_ListNodegroups_599978(path: JsonNode; query: JsonNode;
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
  var valid_599994 = path.getOrDefault("name")
  valid_599994 = validateParameter(valid_599994, JString, required = true,
                                 default = nil)
  if valid_599994 != nil:
    section.add "name", valid_599994
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  section = newJObject()
  var valid_599995 = query.getOrDefault("maxResults")
  valid_599995 = validateParameter(valid_599995, JInt, required = false, default = nil)
  if valid_599995 != nil:
    section.add "maxResults", valid_599995
  var valid_599996 = query.getOrDefault("nextToken")
  valid_599996 = validateParameter(valid_599996, JString, required = false,
                                 default = nil)
  if valid_599996 != nil:
    section.add "nextToken", valid_599996
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_599997 = header.getOrDefault("X-Amz-Date")
  valid_599997 = validateParameter(valid_599997, JString, required = false,
                                 default = nil)
  if valid_599997 != nil:
    section.add "X-Amz-Date", valid_599997
  var valid_599998 = header.getOrDefault("X-Amz-Security-Token")
  valid_599998 = validateParameter(valid_599998, JString, required = false,
                                 default = nil)
  if valid_599998 != nil:
    section.add "X-Amz-Security-Token", valid_599998
  var valid_599999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599999 = validateParameter(valid_599999, JString, required = false,
                                 default = nil)
  if valid_599999 != nil:
    section.add "X-Amz-Content-Sha256", valid_599999
  var valid_600000 = header.getOrDefault("X-Amz-Algorithm")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Algorithm", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Signature")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Signature", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-SignedHeaders", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Credential")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Credential", valid_600003
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600004: Call_ListNodegroups_599977; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ## 
  let valid = call_600004.validator(path, query, header, formData, body)
  let scheme = call_600004.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600004.url(scheme.get, call_600004.host, call_600004.base,
                         call_600004.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600004, url, valid)

proc call*(call_600005: Call_ListNodegroups_599977; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listNodegroups
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that you would like to list node groups in.
  ##   maxResults: int
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  var path_600006 = newJObject()
  var query_600007 = newJObject()
  add(path_600006, "name", newJString(name))
  add(query_600007, "maxResults", newJInt(maxResults))
  add(query_600007, "nextToken", newJString(nextToken))
  result = call_600005.call(path_600006, query_600007, nil, nil, nil)

var listNodegroups* = Call_ListNodegroups_599977(name: "listNodegroups",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_ListNodegroups_599978,
    base: "/", url: url_ListNodegroups_599979, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_600024 = ref object of OpenApiRestCall_599369
proc url_DescribeCluster_600026(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCluster_600025(path: JsonNode; query: JsonNode;
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
  var valid_600027 = path.getOrDefault("name")
  valid_600027 = validateParameter(valid_600027, JString, required = true,
                                 default = nil)
  if valid_600027 != nil:
    section.add "name", valid_600027
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600028 = header.getOrDefault("X-Amz-Date")
  valid_600028 = validateParameter(valid_600028, JString, required = false,
                                 default = nil)
  if valid_600028 != nil:
    section.add "X-Amz-Date", valid_600028
  var valid_600029 = header.getOrDefault("X-Amz-Security-Token")
  valid_600029 = validateParameter(valid_600029, JString, required = false,
                                 default = nil)
  if valid_600029 != nil:
    section.add "X-Amz-Security-Token", valid_600029
  var valid_600030 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Content-Sha256", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-Algorithm")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Algorithm", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Signature")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Signature", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-SignedHeaders", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Credential")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Credential", valid_600034
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600035: Call_DescribeCluster_600024; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ## 
  let valid = call_600035.validator(path, query, header, formData, body)
  let scheme = call_600035.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600035.url(scheme.get, call_600035.host, call_600035.base,
                         call_600035.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600035, url, valid)

proc call*(call_600036: Call_DescribeCluster_600024; name: string): Recallable =
  ## describeCluster
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ##   name: string (required)
  ##       : The name of the cluster to describe.
  var path_600037 = newJObject()
  add(path_600037, "name", newJString(name))
  result = call_600036.call(path_600037, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_600024(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters/{name}",
    validator: validate_DescribeCluster_600025, base: "/", url: url_DescribeCluster_600026,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_600038 = ref object of OpenApiRestCall_599369
proc url_DeleteCluster_600040(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_600039(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the cluster to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_600041 = path.getOrDefault("name")
  valid_600041 = validateParameter(valid_600041, JString, required = true,
                                 default = nil)
  if valid_600041 != nil:
    section.add "name", valid_600041
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600042 = header.getOrDefault("X-Amz-Date")
  valid_600042 = validateParameter(valid_600042, JString, required = false,
                                 default = nil)
  if valid_600042 != nil:
    section.add "X-Amz-Date", valid_600042
  var valid_600043 = header.getOrDefault("X-Amz-Security-Token")
  valid_600043 = validateParameter(valid_600043, JString, required = false,
                                 default = nil)
  if valid_600043 != nil:
    section.add "X-Amz-Security-Token", valid_600043
  var valid_600044 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "X-Amz-Content-Sha256", valid_600044
  var valid_600045 = header.getOrDefault("X-Amz-Algorithm")
  valid_600045 = validateParameter(valid_600045, JString, required = false,
                                 default = nil)
  if valid_600045 != nil:
    section.add "X-Amz-Algorithm", valid_600045
  var valid_600046 = header.getOrDefault("X-Amz-Signature")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "X-Amz-Signature", valid_600046
  var valid_600047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "X-Amz-SignedHeaders", valid_600047
  var valid_600048 = header.getOrDefault("X-Amz-Credential")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Credential", valid_600048
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600049: Call_DeleteCluster_600038; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a>.</p>
  ## 
  let valid = call_600049.validator(path, query, header, formData, body)
  let scheme = call_600049.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600049.url(scheme.get, call_600049.host, call_600049.base,
                         call_600049.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600049, url, valid)

proc call*(call_600050: Call_DeleteCluster_600038; name: string): Recallable =
  ## deleteCluster
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a>.</p>
  ##   name: string (required)
  ##       : The name of the cluster to delete.
  var path_600051 = newJObject()
  add(path_600051, "name", newJString(name))
  result = call_600050.call(path_600051, nil, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_600038(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}", validator: validate_DeleteCluster_600039, base: "/",
    url: url_DeleteCluster_600040, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodegroup_600052 = ref object of OpenApiRestCall_599369
proc url_DescribeNodegroup_600054(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeNodegroup_600053(path: JsonNode; query: JsonNode;
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
  var valid_600055 = path.getOrDefault("name")
  valid_600055 = validateParameter(valid_600055, JString, required = true,
                                 default = nil)
  if valid_600055 != nil:
    section.add "name", valid_600055
  var valid_600056 = path.getOrDefault("nodegroupName")
  valid_600056 = validateParameter(valid_600056, JString, required = true,
                                 default = nil)
  if valid_600056 != nil:
    section.add "nodegroupName", valid_600056
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600057 = header.getOrDefault("X-Amz-Date")
  valid_600057 = validateParameter(valid_600057, JString, required = false,
                                 default = nil)
  if valid_600057 != nil:
    section.add "X-Amz-Date", valid_600057
  var valid_600058 = header.getOrDefault("X-Amz-Security-Token")
  valid_600058 = validateParameter(valid_600058, JString, required = false,
                                 default = nil)
  if valid_600058 != nil:
    section.add "X-Amz-Security-Token", valid_600058
  var valid_600059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600059 = validateParameter(valid_600059, JString, required = false,
                                 default = nil)
  if valid_600059 != nil:
    section.add "X-Amz-Content-Sha256", valid_600059
  var valid_600060 = header.getOrDefault("X-Amz-Algorithm")
  valid_600060 = validateParameter(valid_600060, JString, required = false,
                                 default = nil)
  if valid_600060 != nil:
    section.add "X-Amz-Algorithm", valid_600060
  var valid_600061 = header.getOrDefault("X-Amz-Signature")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Signature", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-SignedHeaders", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Credential")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Credential", valid_600063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600064: Call_DescribeNodegroup_600052; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptive information about an Amazon EKS node group.
  ## 
  let valid = call_600064.validator(path, query, header, formData, body)
  let scheme = call_600064.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600064.url(scheme.get, call_600064.host, call_600064.base,
                         call_600064.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600064, url, valid)

proc call*(call_600065: Call_DescribeNodegroup_600052; name: string;
          nodegroupName: string): Recallable =
  ## describeNodegroup
  ## Returns descriptive information about an Amazon EKS node group.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to describe.
  var path_600066 = newJObject()
  add(path_600066, "name", newJString(name))
  add(path_600066, "nodegroupName", newJString(nodegroupName))
  result = call_600065.call(path_600066, nil, nil, nil, nil)

var describeNodegroup* = Call_DescribeNodegroup_600052(name: "describeNodegroup",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DescribeNodegroup_600053, base: "/",
    url: url_DescribeNodegroup_600054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNodegroup_600067 = ref object of OpenApiRestCall_599369
proc url_DeleteNodegroup_600069(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNodegroup_600068(path: JsonNode; query: JsonNode;
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
  var valid_600070 = path.getOrDefault("name")
  valid_600070 = validateParameter(valid_600070, JString, required = true,
                                 default = nil)
  if valid_600070 != nil:
    section.add "name", valid_600070
  var valid_600071 = path.getOrDefault("nodegroupName")
  valid_600071 = validateParameter(valid_600071, JString, required = true,
                                 default = nil)
  if valid_600071 != nil:
    section.add "nodegroupName", valid_600071
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600072 = header.getOrDefault("X-Amz-Date")
  valid_600072 = validateParameter(valid_600072, JString, required = false,
                                 default = nil)
  if valid_600072 != nil:
    section.add "X-Amz-Date", valid_600072
  var valid_600073 = header.getOrDefault("X-Amz-Security-Token")
  valid_600073 = validateParameter(valid_600073, JString, required = false,
                                 default = nil)
  if valid_600073 != nil:
    section.add "X-Amz-Security-Token", valid_600073
  var valid_600074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600074 = validateParameter(valid_600074, JString, required = false,
                                 default = nil)
  if valid_600074 != nil:
    section.add "X-Amz-Content-Sha256", valid_600074
  var valid_600075 = header.getOrDefault("X-Amz-Algorithm")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "X-Amz-Algorithm", valid_600075
  var valid_600076 = header.getOrDefault("X-Amz-Signature")
  valid_600076 = validateParameter(valid_600076, JString, required = false,
                                 default = nil)
  if valid_600076 != nil:
    section.add "X-Amz-Signature", valid_600076
  var valid_600077 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "X-Amz-SignedHeaders", valid_600077
  var valid_600078 = header.getOrDefault("X-Amz-Credential")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "X-Amz-Credential", valid_600078
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600079: Call_DeleteNodegroup_600067; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon EKS node group for a cluster.
  ## 
  let valid = call_600079.validator(path, query, header, formData, body)
  let scheme = call_600079.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600079.url(scheme.get, call_600079.host, call_600079.base,
                         call_600079.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600079, url, valid)

proc call*(call_600080: Call_DeleteNodegroup_600067; name: string;
          nodegroupName: string): Recallable =
  ## deleteNodegroup
  ## Deletes an Amazon EKS node group for a cluster.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with your node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to delete.
  var path_600081 = newJObject()
  add(path_600081, "name", newJString(name))
  add(path_600081, "nodegroupName", newJString(nodegroupName))
  result = call_600080.call(path_600081, nil, nil, nil, nil)

var deleteNodegroup* = Call_DeleteNodegroup_600067(name: "deleteNodegroup",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DeleteNodegroup_600068, base: "/", url: url_DeleteNodegroup_600069,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUpdate_600082 = ref object of OpenApiRestCall_599369
proc url_DescribeUpdate_600084(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUpdate_600083(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster associated with the update.
  ##   updateId: JString (required)
  ##           : The ID of the update to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_600085 = path.getOrDefault("name")
  valid_600085 = validateParameter(valid_600085, JString, required = true,
                                 default = nil)
  if valid_600085 != nil:
    section.add "name", valid_600085
  var valid_600086 = path.getOrDefault("updateId")
  valid_600086 = validateParameter(valid_600086, JString, required = true,
                                 default = nil)
  if valid_600086 != nil:
    section.add "updateId", valid_600086
  result.add "path", section
  ## parameters in `query` object:
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS node group associated with the update.
  section = newJObject()
  var valid_600087 = query.getOrDefault("nodegroupName")
  valid_600087 = validateParameter(valid_600087, JString, required = false,
                                 default = nil)
  if valid_600087 != nil:
    section.add "nodegroupName", valid_600087
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600088 = header.getOrDefault("X-Amz-Date")
  valid_600088 = validateParameter(valid_600088, JString, required = false,
                                 default = nil)
  if valid_600088 != nil:
    section.add "X-Amz-Date", valid_600088
  var valid_600089 = header.getOrDefault("X-Amz-Security-Token")
  valid_600089 = validateParameter(valid_600089, JString, required = false,
                                 default = nil)
  if valid_600089 != nil:
    section.add "X-Amz-Security-Token", valid_600089
  var valid_600090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600090 = validateParameter(valid_600090, JString, required = false,
                                 default = nil)
  if valid_600090 != nil:
    section.add "X-Amz-Content-Sha256", valid_600090
  var valid_600091 = header.getOrDefault("X-Amz-Algorithm")
  valid_600091 = validateParameter(valid_600091, JString, required = false,
                                 default = nil)
  if valid_600091 != nil:
    section.add "X-Amz-Algorithm", valid_600091
  var valid_600092 = header.getOrDefault("X-Amz-Signature")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Signature", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-SignedHeaders", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Credential")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Credential", valid_600094
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600095: Call_DescribeUpdate_600082; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ## 
  let valid = call_600095.validator(path, query, header, formData, body)
  let scheme = call_600095.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600095.url(scheme.get, call_600095.host, call_600095.base,
                         call_600095.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600095, url, valid)

proc call*(call_600096: Call_DescribeUpdate_600082; name: string; updateId: string;
          nodegroupName: string = ""): Recallable =
  ## describeUpdate
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ##   nodegroupName: string
  ##                : The name of the Amazon EKS node group associated with the update.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the update.
  ##   updateId: string (required)
  ##           : The ID of the update to describe.
  var path_600097 = newJObject()
  var query_600098 = newJObject()
  add(query_600098, "nodegroupName", newJString(nodegroupName))
  add(path_600097, "name", newJString(name))
  add(path_600097, "updateId", newJString(updateId))
  result = call_600096.call(path_600097, query_600098, nil, nil, nil)

var describeUpdate* = Call_DescribeUpdate_600082(name: "describeUpdate",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/updates/{updateId}",
    validator: validate_DescribeUpdate_600083, base: "/", url: url_DescribeUpdate_600084,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_600113 = ref object of OpenApiRestCall_599369
proc url_TagResource_600115(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_600114(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600116 = path.getOrDefault("resourceArn")
  valid_600116 = validateParameter(valid_600116, JString, required = true,
                                 default = nil)
  if valid_600116 != nil:
    section.add "resourceArn", valid_600116
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600117 = header.getOrDefault("X-Amz-Date")
  valid_600117 = validateParameter(valid_600117, JString, required = false,
                                 default = nil)
  if valid_600117 != nil:
    section.add "X-Amz-Date", valid_600117
  var valid_600118 = header.getOrDefault("X-Amz-Security-Token")
  valid_600118 = validateParameter(valid_600118, JString, required = false,
                                 default = nil)
  if valid_600118 != nil:
    section.add "X-Amz-Security-Token", valid_600118
  var valid_600119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600119 = validateParameter(valid_600119, JString, required = false,
                                 default = nil)
  if valid_600119 != nil:
    section.add "X-Amz-Content-Sha256", valid_600119
  var valid_600120 = header.getOrDefault("X-Amz-Algorithm")
  valid_600120 = validateParameter(valid_600120, JString, required = false,
                                 default = nil)
  if valid_600120 != nil:
    section.add "X-Amz-Algorithm", valid_600120
  var valid_600121 = header.getOrDefault("X-Amz-Signature")
  valid_600121 = validateParameter(valid_600121, JString, required = false,
                                 default = nil)
  if valid_600121 != nil:
    section.add "X-Amz-Signature", valid_600121
  var valid_600122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600122 = validateParameter(valid_600122, JString, required = false,
                                 default = nil)
  if valid_600122 != nil:
    section.add "X-Amz-SignedHeaders", valid_600122
  var valid_600123 = header.getOrDefault("X-Amz-Credential")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Credential", valid_600123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600125: Call_TagResource_600113; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ## 
  let valid = call_600125.validator(path, query, header, formData, body)
  let scheme = call_600125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600125.url(scheme.get, call_600125.host, call_600125.base,
                         call_600125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600125, url, valid)

proc call*(call_600126: Call_TagResource_600113; body: JsonNode; resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to which to add tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_600127 = newJObject()
  var body_600128 = newJObject()
  if body != nil:
    body_600128 = body
  add(path_600127, "resourceArn", newJString(resourceArn))
  result = call_600126.call(path_600127, nil, nil, nil, body_600128)

var tagResource* = Call_TagResource_600113(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "eks.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_600114,
                                        base: "/", url: url_TagResource_600115,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600099 = ref object of OpenApiRestCall_599369
proc url_ListTagsForResource_600101(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_600100(path: JsonNode; query: JsonNode;
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
  var valid_600102 = path.getOrDefault("resourceArn")
  valid_600102 = validateParameter(valid_600102, JString, required = true,
                                 default = nil)
  if valid_600102 != nil:
    section.add "resourceArn", valid_600102
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600103 = header.getOrDefault("X-Amz-Date")
  valid_600103 = validateParameter(valid_600103, JString, required = false,
                                 default = nil)
  if valid_600103 != nil:
    section.add "X-Amz-Date", valid_600103
  var valid_600104 = header.getOrDefault("X-Amz-Security-Token")
  valid_600104 = validateParameter(valid_600104, JString, required = false,
                                 default = nil)
  if valid_600104 != nil:
    section.add "X-Amz-Security-Token", valid_600104
  var valid_600105 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600105 = validateParameter(valid_600105, JString, required = false,
                                 default = nil)
  if valid_600105 != nil:
    section.add "X-Amz-Content-Sha256", valid_600105
  var valid_600106 = header.getOrDefault("X-Amz-Algorithm")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "X-Amz-Algorithm", valid_600106
  var valid_600107 = header.getOrDefault("X-Amz-Signature")
  valid_600107 = validateParameter(valid_600107, JString, required = false,
                                 default = nil)
  if valid_600107 != nil:
    section.add "X-Amz-Signature", valid_600107
  var valid_600108 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "X-Amz-SignedHeaders", valid_600108
  var valid_600109 = header.getOrDefault("X-Amz-Credential")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "X-Amz-Credential", valid_600109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600110: Call_ListTagsForResource_600099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon EKS resource.
  ## 
  let valid = call_600110.validator(path, query, header, formData, body)
  let scheme = call_600110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600110.url(scheme.get, call_600110.host, call_600110.base,
                         call_600110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600110, url, valid)

proc call*(call_600111: Call_ListTagsForResource_600099; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon EKS resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_600112 = newJObject()
  add(path_600112, "resourceArn", newJString(resourceArn))
  result = call_600111.call(path_600112, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600099(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_600100, base: "/",
    url: url_ListTagsForResource_600101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterVersion_600147 = ref object of OpenApiRestCall_599369
proc url_UpdateClusterVersion_600149(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterVersion_600148(path: JsonNode; query: JsonNode;
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
  var valid_600150 = path.getOrDefault("name")
  valid_600150 = validateParameter(valid_600150, JString, required = true,
                                 default = nil)
  if valid_600150 != nil:
    section.add "name", valid_600150
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600151 = header.getOrDefault("X-Amz-Date")
  valid_600151 = validateParameter(valid_600151, JString, required = false,
                                 default = nil)
  if valid_600151 != nil:
    section.add "X-Amz-Date", valid_600151
  var valid_600152 = header.getOrDefault("X-Amz-Security-Token")
  valid_600152 = validateParameter(valid_600152, JString, required = false,
                                 default = nil)
  if valid_600152 != nil:
    section.add "X-Amz-Security-Token", valid_600152
  var valid_600153 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600153 = validateParameter(valid_600153, JString, required = false,
                                 default = nil)
  if valid_600153 != nil:
    section.add "X-Amz-Content-Sha256", valid_600153
  var valid_600154 = header.getOrDefault("X-Amz-Algorithm")
  valid_600154 = validateParameter(valid_600154, JString, required = false,
                                 default = nil)
  if valid_600154 != nil:
    section.add "X-Amz-Algorithm", valid_600154
  var valid_600155 = header.getOrDefault("X-Amz-Signature")
  valid_600155 = validateParameter(valid_600155, JString, required = false,
                                 default = nil)
  if valid_600155 != nil:
    section.add "X-Amz-Signature", valid_600155
  var valid_600156 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600156 = validateParameter(valid_600156, JString, required = false,
                                 default = nil)
  if valid_600156 != nil:
    section.add "X-Amz-SignedHeaders", valid_600156
  var valid_600157 = header.getOrDefault("X-Amz-Credential")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Credential", valid_600157
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600159: Call_UpdateClusterVersion_600147; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ## 
  let valid = call_600159.validator(path, query, header, formData, body)
  let scheme = call_600159.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600159.url(scheme.get, call_600159.host, call_600159.base,
                         call_600159.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600159, url, valid)

proc call*(call_600160: Call_UpdateClusterVersion_600147; name: string;
          body: JsonNode): Recallable =
  ## updateClusterVersion
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_600161 = newJObject()
  var body_600162 = newJObject()
  add(path_600161, "name", newJString(name))
  if body != nil:
    body_600162 = body
  result = call_600160.call(path_600161, nil, nil, nil, body_600162)

var updateClusterVersion* = Call_UpdateClusterVersion_600147(
    name: "updateClusterVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/updates",
    validator: validate_UpdateClusterVersion_600148, base: "/",
    url: url_UpdateClusterVersion_600149, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUpdates_600129 = ref object of OpenApiRestCall_599369
proc url_ListUpdates_600131(protocol: Scheme; host: string; base: string;
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

proc validate_ListUpdates_600130(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600132 = path.getOrDefault("name")
  valid_600132 = validateParameter(valid_600132, JString, required = true,
                                 default = nil)
  if valid_600132 != nil:
    section.add "name", valid_600132
  result.add "path", section
  ## parameters in `query` object:
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS managed node group to list updates for.
  ##   maxResults: JInt
  ##             : The maximum number of update results returned by <code>ListUpdates</code> in paginated output. When you use this parameter, <code>ListUpdates</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListUpdates</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListUpdates</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListUpdates</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  section = newJObject()
  var valid_600133 = query.getOrDefault("nodegroupName")
  valid_600133 = validateParameter(valid_600133, JString, required = false,
                                 default = nil)
  if valid_600133 != nil:
    section.add "nodegroupName", valid_600133
  var valid_600134 = query.getOrDefault("maxResults")
  valid_600134 = validateParameter(valid_600134, JInt, required = false, default = nil)
  if valid_600134 != nil:
    section.add "maxResults", valid_600134
  var valid_600135 = query.getOrDefault("nextToken")
  valid_600135 = validateParameter(valid_600135, JString, required = false,
                                 default = nil)
  if valid_600135 != nil:
    section.add "nextToken", valid_600135
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600136 = header.getOrDefault("X-Amz-Date")
  valid_600136 = validateParameter(valid_600136, JString, required = false,
                                 default = nil)
  if valid_600136 != nil:
    section.add "X-Amz-Date", valid_600136
  var valid_600137 = header.getOrDefault("X-Amz-Security-Token")
  valid_600137 = validateParameter(valid_600137, JString, required = false,
                                 default = nil)
  if valid_600137 != nil:
    section.add "X-Amz-Security-Token", valid_600137
  var valid_600138 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "X-Amz-Content-Sha256", valid_600138
  var valid_600139 = header.getOrDefault("X-Amz-Algorithm")
  valid_600139 = validateParameter(valid_600139, JString, required = false,
                                 default = nil)
  if valid_600139 != nil:
    section.add "X-Amz-Algorithm", valid_600139
  var valid_600140 = header.getOrDefault("X-Amz-Signature")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "X-Amz-Signature", valid_600140
  var valid_600141 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "X-Amz-SignedHeaders", valid_600141
  var valid_600142 = header.getOrDefault("X-Amz-Credential")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Credential", valid_600142
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600143: Call_ListUpdates_600129; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
  ## 
  let valid = call_600143.validator(path, query, header, formData, body)
  let scheme = call_600143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600143.url(scheme.get, call_600143.host, call_600143.base,
                         call_600143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600143, url, valid)

proc call*(call_600144: Call_ListUpdates_600129; name: string;
          nodegroupName: string = ""; maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listUpdates
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
  ##   nodegroupName: string
  ##                : The name of the Amazon EKS managed node group to list updates for.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to list updates for.
  ##   maxResults: int
  ##             : The maximum number of update results returned by <code>ListUpdates</code> in paginated output. When you use this parameter, <code>ListUpdates</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListUpdates</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListUpdates</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListUpdates</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  var path_600145 = newJObject()
  var query_600146 = newJObject()
  add(query_600146, "nodegroupName", newJString(nodegroupName))
  add(path_600145, "name", newJString(name))
  add(query_600146, "maxResults", newJInt(maxResults))
  add(query_600146, "nextToken", newJString(nextToken))
  result = call_600144.call(path_600145, query_600146, nil, nil, nil)

var listUpdates* = Call_ListUpdates_600129(name: "listUpdates",
                                        meth: HttpMethod.HttpGet,
                                        host: "eks.amazonaws.com",
                                        route: "/clusters/{name}/updates",
                                        validator: validate_ListUpdates_600130,
                                        base: "/", url: url_ListUpdates_600131,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_600163 = ref object of OpenApiRestCall_599369
proc url_UntagResource_600165(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_600164(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_600166 = path.getOrDefault("resourceArn")
  valid_600166 = validateParameter(valid_600166, JString, required = true,
                                 default = nil)
  if valid_600166 != nil:
    section.add "resourceArn", valid_600166
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600167 = query.getOrDefault("tagKeys")
  valid_600167 = validateParameter(valid_600167, JArray, required = true, default = nil)
  if valid_600167 != nil:
    section.add "tagKeys", valid_600167
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600168 = header.getOrDefault("X-Amz-Date")
  valid_600168 = validateParameter(valid_600168, JString, required = false,
                                 default = nil)
  if valid_600168 != nil:
    section.add "X-Amz-Date", valid_600168
  var valid_600169 = header.getOrDefault("X-Amz-Security-Token")
  valid_600169 = validateParameter(valid_600169, JString, required = false,
                                 default = nil)
  if valid_600169 != nil:
    section.add "X-Amz-Security-Token", valid_600169
  var valid_600170 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600170 = validateParameter(valid_600170, JString, required = false,
                                 default = nil)
  if valid_600170 != nil:
    section.add "X-Amz-Content-Sha256", valid_600170
  var valid_600171 = header.getOrDefault("X-Amz-Algorithm")
  valid_600171 = validateParameter(valid_600171, JString, required = false,
                                 default = nil)
  if valid_600171 != nil:
    section.add "X-Amz-Algorithm", valid_600171
  var valid_600172 = header.getOrDefault("X-Amz-Signature")
  valid_600172 = validateParameter(valid_600172, JString, required = false,
                                 default = nil)
  if valid_600172 != nil:
    section.add "X-Amz-Signature", valid_600172
  var valid_600173 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-SignedHeaders", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Credential")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Credential", valid_600174
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600175: Call_UntagResource_600163; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_600175.validator(path, query, header, formData, body)
  let scheme = call_600175.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600175.url(scheme.get, call_600175.host, call_600175.base,
                         call_600175.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600175, url, valid)

proc call*(call_600176: Call_UntagResource_600163; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource from which to delete tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_600177 = newJObject()
  var query_600178 = newJObject()
  if tagKeys != nil:
    query_600178.add "tagKeys", tagKeys
  add(path_600177, "resourceArn", newJString(resourceArn))
  result = call_600176.call(path_600177, query_600178, nil, nil, nil)

var untagResource* = Call_UntagResource_600163(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_600164,
    base: "/", url: url_UntagResource_600165, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfig_600179 = ref object of OpenApiRestCall_599369
proc url_UpdateClusterConfig_600181(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterConfig_600180(path: JsonNode; query: JsonNode;
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
  var valid_600182 = path.getOrDefault("name")
  valid_600182 = validateParameter(valid_600182, JString, required = true,
                                 default = nil)
  if valid_600182 != nil:
    section.add "name", valid_600182
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600183 = header.getOrDefault("X-Amz-Date")
  valid_600183 = validateParameter(valid_600183, JString, required = false,
                                 default = nil)
  if valid_600183 != nil:
    section.add "X-Amz-Date", valid_600183
  var valid_600184 = header.getOrDefault("X-Amz-Security-Token")
  valid_600184 = validateParameter(valid_600184, JString, required = false,
                                 default = nil)
  if valid_600184 != nil:
    section.add "X-Amz-Security-Token", valid_600184
  var valid_600185 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600185 = validateParameter(valid_600185, JString, required = false,
                                 default = nil)
  if valid_600185 != nil:
    section.add "X-Amz-Content-Sha256", valid_600185
  var valid_600186 = header.getOrDefault("X-Amz-Algorithm")
  valid_600186 = validateParameter(valid_600186, JString, required = false,
                                 default = nil)
  if valid_600186 != nil:
    section.add "X-Amz-Algorithm", valid_600186
  var valid_600187 = header.getOrDefault("X-Amz-Signature")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Signature", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-SignedHeaders", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Credential")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Credential", valid_600189
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600191: Call_UpdateClusterConfig_600179; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ## 
  let valid = call_600191.validator(path, query, header, formData, body)
  let scheme = call_600191.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600191.url(scheme.get, call_600191.host, call_600191.base,
                         call_600191.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600191, url, valid)

proc call*(call_600192: Call_UpdateClusterConfig_600179; name: string; body: JsonNode): Recallable =
  ## updateClusterConfig
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_600193 = newJObject()
  var body_600194 = newJObject()
  add(path_600193, "name", newJString(name))
  if body != nil:
    body_600194 = body
  result = call_600192.call(path_600193, nil, nil, nil, body_600194)

var updateClusterConfig* = Call_UpdateClusterConfig_600179(
    name: "updateClusterConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/update-config",
    validator: validate_UpdateClusterConfig_600180, base: "/",
    url: url_UpdateClusterConfig_600181, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupConfig_600195 = ref object of OpenApiRestCall_599369
proc url_UpdateNodegroupConfig_600197(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNodegroupConfig_600196(path: JsonNode; query: JsonNode;
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
  var valid_600198 = path.getOrDefault("name")
  valid_600198 = validateParameter(valid_600198, JString, required = true,
                                 default = nil)
  if valid_600198 != nil:
    section.add "name", valid_600198
  var valid_600199 = path.getOrDefault("nodegroupName")
  valid_600199 = validateParameter(valid_600199, JString, required = true,
                                 default = nil)
  if valid_600199 != nil:
    section.add "nodegroupName", valid_600199
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600200 = header.getOrDefault("X-Amz-Date")
  valid_600200 = validateParameter(valid_600200, JString, required = false,
                                 default = nil)
  if valid_600200 != nil:
    section.add "X-Amz-Date", valid_600200
  var valid_600201 = header.getOrDefault("X-Amz-Security-Token")
  valid_600201 = validateParameter(valid_600201, JString, required = false,
                                 default = nil)
  if valid_600201 != nil:
    section.add "X-Amz-Security-Token", valid_600201
  var valid_600202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600202 = validateParameter(valid_600202, JString, required = false,
                                 default = nil)
  if valid_600202 != nil:
    section.add "X-Amz-Content-Sha256", valid_600202
  var valid_600203 = header.getOrDefault("X-Amz-Algorithm")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Algorithm", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Signature")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Signature", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-SignedHeaders", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Credential")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Credential", valid_600206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600208: Call_UpdateNodegroupConfig_600195; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ## 
  let valid = call_600208.validator(path, query, header, formData, body)
  let scheme = call_600208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600208.url(scheme.get, call_600208.host, call_600208.base,
                         call_600208.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600208, url, valid)

proc call*(call_600209: Call_UpdateNodegroupConfig_600195; name: string;
          nodegroupName: string; body: JsonNode): Recallable =
  ## updateNodegroupConfig
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that the managed node group resides in.
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  ##   body: JObject (required)
  var path_600210 = newJObject()
  var body_600211 = newJObject()
  add(path_600210, "name", newJString(name))
  add(path_600210, "nodegroupName", newJString(nodegroupName))
  if body != nil:
    body_600211 = body
  result = call_600209.call(path_600210, nil, nil, nil, body_600211)

var updateNodegroupConfig* = Call_UpdateNodegroupConfig_600195(
    name: "updateNodegroupConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-config",
    validator: validate_UpdateNodegroupConfig_600196, base: "/",
    url: url_UpdateNodegroupConfig_600197, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupVersion_600212 = ref object of OpenApiRestCall_599369
proc url_UpdateNodegroupVersion_600214(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNodegroupVersion_600213(path: JsonNode; query: JsonNode;
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
  var valid_600215 = path.getOrDefault("name")
  valid_600215 = validateParameter(valid_600215, JString, required = true,
                                 default = nil)
  if valid_600215 != nil:
    section.add "name", valid_600215
  var valid_600216 = path.getOrDefault("nodegroupName")
  valid_600216 = validateParameter(valid_600216, JString, required = true,
                                 default = nil)
  if valid_600216 != nil:
    section.add "nodegroupName", valid_600216
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Content-Sha256", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Algorithm")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Algorithm", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Signature")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Signature", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-SignedHeaders", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Credential")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Credential", valid_600223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600225: Call_UpdateNodegroupVersion_600212; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ## 
  let valid = call_600225.validator(path, query, header, formData, body)
  let scheme = call_600225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600225.url(scheme.get, call_600225.host, call_600225.base,
                         call_600225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600225, url, valid)

proc call*(call_600226: Call_UpdateNodegroupVersion_600212; name: string;
          nodegroupName: string; body: JsonNode): Recallable =
  ## updateNodegroupVersion
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with the managed node group to update.
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  ##   body: JObject (required)
  var path_600227 = newJObject()
  var body_600228 = newJObject()
  add(path_600227, "name", newJString(name))
  add(path_600227, "nodegroupName", newJString(nodegroupName))
  if body != nil:
    body_600228 = body
  result = call_600226.call(path_600227, nil, nil, nil, body_600228)

var updateNodegroupVersion* = Call_UpdateNodegroupVersion_600212(
    name: "updateNodegroupVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-version",
    validator: validate_UpdateNodegroupVersion_600213, base: "/",
    url: url_UpdateNodegroupVersion_600214, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
