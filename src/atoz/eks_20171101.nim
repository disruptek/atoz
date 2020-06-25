
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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

  OpenApiRestCall_21625437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625437): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateCluster_21626021 = ref object of OpenApiRestCall_21625437
proc url_CreateCluster_21626023(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateCluster_21626022(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626024 = header.getOrDefault("X-Amz-Date")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Date", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Security-Token", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Algorithm", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Signature")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Signature", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Credential")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Credential", valid_21626030
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

proc call*(call_21626032: Call_CreateCluster_21626021; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_CreateCluster_21626021; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   body: JObject (required)
  var body_21626034 = newJObject()
  if body != nil:
    body_21626034 = body
  result = call_21626033.call(nil, nil, nil, nil, body_21626034)

var createCluster* = Call_CreateCluster_21626021(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_CreateCluster_21626022, base: "/",
    makeUrl: url_CreateCluster_21626023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_21625781 = ref object of OpenApiRestCall_21625437
proc url_ListClusters_21625783(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListClusters_21625782(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21625884 = query.getOrDefault("maxResults")
  valid_21625884 = validateParameter(valid_21625884, JInt, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "maxResults", valid_21625884
  var valid_21625885 = query.getOrDefault("nextToken")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "nextToken", valid_21625885
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
  var valid_21625886 = header.getOrDefault("X-Amz-Date")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Date", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Security-Token", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Algorithm", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Signature")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Signature", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Credential")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Credential", valid_21625892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625917: Call_ListClusters_21625781; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ## 
  let valid = call_21625917.validator(path, query, header, formData, body, _)
  let scheme = call_21625917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625917.makeUrl(scheme.get, call_21625917.host, call_21625917.base,
                               call_21625917.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625917, uri, valid, _)

proc call*(call_21625980: Call_ListClusters_21625781; maxResults: int = 0;
          nextToken: string = ""): Recallable =
  ## listClusters
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ##   maxResults: int
  ##             : The maximum number of cluster results returned by <code>ListClusters</code> in paginated output. When you use this parameter, <code>ListClusters</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListClusters</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListClusters</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListClusters</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.</p> <note> <p>This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  var query_21625982 = newJObject()
  add(query_21625982, "maxResults", newJInt(maxResults))
  add(query_21625982, "nextToken", newJString(nextToken))
  result = call_21625980.call(nil, query_21625982, nil, nil, nil)

var listClusters* = Call_ListClusters_21625781(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_ListClusters_21625782, base: "/", makeUrl: url_ListClusters_21625783,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFargateProfile_21626065 = ref object of OpenApiRestCall_21625437
proc url_CreateFargateProfile_21626067(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateFargateProfile_21626066(path: JsonNode; query: JsonNode;
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
  var valid_21626068 = path.getOrDefault("name")
  valid_21626068 = validateParameter(valid_21626068, JString, required = true,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "name", valid_21626068
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
  var valid_21626069 = header.getOrDefault("X-Amz-Date")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Date", valid_21626069
  var valid_21626070 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626070 = validateParameter(valid_21626070, JString, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "X-Amz-Security-Token", valid_21626070
  var valid_21626071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626071
  var valid_21626072 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "X-Amz-Algorithm", valid_21626072
  var valid_21626073 = header.getOrDefault("X-Amz-Signature")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Signature", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Credential")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Credential", valid_21626075
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

proc call*(call_21626077: Call_CreateFargateProfile_21626065; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  let valid = call_21626077.validator(path, query, header, formData, body, _)
  let scheme = call_21626077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626077.makeUrl(scheme.get, call_21626077.host, call_21626077.base,
                               call_21626077.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626077, uri, valid, _)

proc call*(call_21626078: Call_CreateFargateProfile_21626065; name: string;
          body: JsonNode): Recallable =
  ## createFargateProfile
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to apply the Fargate profile to.
  ##   body: JObject (required)
  var path_21626079 = newJObject()
  var body_21626080 = newJObject()
  add(path_21626079, "name", newJString(name))
  if body != nil:
    body_21626080 = body
  result = call_21626078.call(path_21626079, nil, nil, nil, body_21626080)

var createFargateProfile* = Call_CreateFargateProfile_21626065(
    name: "createFargateProfile", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_CreateFargateProfile_21626066, base: "/",
    makeUrl: url_CreateFargateProfile_21626067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFargateProfiles_21626035 = ref object of OpenApiRestCall_21625437
proc url_ListFargateProfiles_21626037(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListFargateProfiles_21626036(path: JsonNode; query: JsonNode;
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
  var valid_21626051 = path.getOrDefault("name")
  valid_21626051 = validateParameter(valid_21626051, JString, required = true,
                                   default = nil)
  if valid_21626051 != nil:
    section.add "name", valid_21626051
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of Fargate profile results returned by <code>ListFargateProfiles</code> in paginated output. When you use this parameter, <code>ListFargateProfiles</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListFargateProfiles</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListFargateProfiles</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListFargateProfiles</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  section = newJObject()
  var valid_21626052 = query.getOrDefault("maxResults")
  valid_21626052 = validateParameter(valid_21626052, JInt, required = false,
                                   default = nil)
  if valid_21626052 != nil:
    section.add "maxResults", valid_21626052
  var valid_21626053 = query.getOrDefault("nextToken")
  valid_21626053 = validateParameter(valid_21626053, JString, required = false,
                                   default = nil)
  if valid_21626053 != nil:
    section.add "nextToken", valid_21626053
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
  var valid_21626054 = header.getOrDefault("X-Amz-Date")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "X-Amz-Date", valid_21626054
  var valid_21626055 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "X-Amz-Security-Token", valid_21626055
  var valid_21626056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Algorithm", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Signature")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Signature", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Credential")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Credential", valid_21626060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626061: Call_ListFargateProfiles_21626035; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ## 
  let valid = call_21626061.validator(path, query, header, formData, body, _)
  let scheme = call_21626061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626061.makeUrl(scheme.get, call_21626061.host, call_21626061.base,
                               call_21626061.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626061, uri, valid, _)

proc call*(call_21626062: Call_ListFargateProfiles_21626035; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listFargateProfiles
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that you would like to listFargate profiles in.
  ##   maxResults: int
  ##             : The maximum number of Fargate profile results returned by <code>ListFargateProfiles</code> in paginated output. When you use this parameter, <code>ListFargateProfiles</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListFargateProfiles</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListFargateProfiles</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListFargateProfiles</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  var path_21626063 = newJObject()
  var query_21626064 = newJObject()
  add(path_21626063, "name", newJString(name))
  add(query_21626064, "maxResults", newJInt(maxResults))
  add(query_21626064, "nextToken", newJString(nextToken))
  result = call_21626062.call(path_21626063, query_21626064, nil, nil, nil)

var listFargateProfiles* = Call_ListFargateProfiles_21626035(
    name: "listFargateProfiles", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_ListFargateProfiles_21626036, base: "/",
    makeUrl: url_ListFargateProfiles_21626037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNodegroup_21626098 = ref object of OpenApiRestCall_21625437
proc url_CreateNodegroup_21626100(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNodegroup_21626099(path: JsonNode; query: JsonNode;
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
  var valid_21626101 = path.getOrDefault("name")
  valid_21626101 = validateParameter(valid_21626101, JString, required = true,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "name", valid_21626101
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
  var valid_21626102 = header.getOrDefault("X-Amz-Date")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "X-Amz-Date", valid_21626102
  var valid_21626103 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "X-Amz-Security-Token", valid_21626103
  var valid_21626104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Algorithm", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Signature")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Signature", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Credential")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Credential", valid_21626108
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

proc call*(call_21626110: Call_CreateNodegroup_21626098; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ## 
  let valid = call_21626110.validator(path, query, header, formData, body, _)
  let scheme = call_21626110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626110.makeUrl(scheme.get, call_21626110.host, call_21626110.base,
                               call_21626110.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626110, uri, valid, _)

proc call*(call_21626111: Call_CreateNodegroup_21626098; name: string; body: JsonNode): Recallable =
  ## createNodegroup
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ##   name: string (required)
  ##       : The name of the cluster to create the node group in.
  ##   body: JObject (required)
  var path_21626112 = newJObject()
  var body_21626113 = newJObject()
  add(path_21626112, "name", newJString(name))
  if body != nil:
    body_21626113 = body
  result = call_21626111.call(path_21626112, nil, nil, nil, body_21626113)

var createNodegroup* = Call_CreateNodegroup_21626098(name: "createNodegroup",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_CreateNodegroup_21626099,
    base: "/", makeUrl: url_CreateNodegroup_21626100,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodegroups_21626081 = ref object of OpenApiRestCall_21625437
proc url_ListNodegroups_21626083(protocol: Scheme; host: string; base: string;
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

proc validate_ListNodegroups_21626082(path: JsonNode; query: JsonNode;
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
  var valid_21626084 = path.getOrDefault("name")
  valid_21626084 = validateParameter(valid_21626084, JString, required = true,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "name", valid_21626084
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  section = newJObject()
  var valid_21626085 = query.getOrDefault("maxResults")
  valid_21626085 = validateParameter(valid_21626085, JInt, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "maxResults", valid_21626085
  var valid_21626086 = query.getOrDefault("nextToken")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "nextToken", valid_21626086
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
  var valid_21626087 = header.getOrDefault("X-Amz-Date")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Date", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Security-Token", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Algorithm", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Signature")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Signature", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Credential")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Credential", valid_21626093
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626094: Call_ListNodegroups_21626081; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ## 
  let valid = call_21626094.validator(path, query, header, formData, body, _)
  let scheme = call_21626094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626094.makeUrl(scheme.get, call_21626094.host, call_21626094.base,
                               call_21626094.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626094, uri, valid, _)

proc call*(call_21626095: Call_ListNodegroups_21626081; name: string;
          maxResults: int = 0; nextToken: string = ""): Recallable =
  ## listNodegroups
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that you would like to list node groups in.
  ##   maxResults: int
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  var path_21626096 = newJObject()
  var query_21626097 = newJObject()
  add(path_21626096, "name", newJString(name))
  add(query_21626097, "maxResults", newJInt(maxResults))
  add(query_21626097, "nextToken", newJString(nextToken))
  result = call_21626095.call(path_21626096, query_21626097, nil, nil, nil)

var listNodegroups* = Call_ListNodegroups_21626081(name: "listNodegroups",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_ListNodegroups_21626082,
    base: "/", makeUrl: url_ListNodegroups_21626083,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_21626114 = ref object of OpenApiRestCall_21625437
proc url_DescribeCluster_21626116(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCluster_21626115(path: JsonNode; query: JsonNode;
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
  var valid_21626117 = path.getOrDefault("name")
  valid_21626117 = validateParameter(valid_21626117, JString, required = true,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "name", valid_21626117
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
  var valid_21626118 = header.getOrDefault("X-Amz-Date")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Date", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Security-Token", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Algorithm", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Signature")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Signature", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Credential")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Credential", valid_21626124
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626125: Call_DescribeCluster_21626114; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ## 
  let valid = call_21626125.validator(path, query, header, formData, body, _)
  let scheme = call_21626125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626125.makeUrl(scheme.get, call_21626125.host, call_21626125.base,
                               call_21626125.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626125, uri, valid, _)

proc call*(call_21626126: Call_DescribeCluster_21626114; name: string): Recallable =
  ## describeCluster
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ##   name: string (required)
  ##       : The name of the cluster to describe.
  var path_21626127 = newJObject()
  add(path_21626127, "name", newJString(name))
  result = call_21626126.call(path_21626127, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_21626114(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters/{name}",
    validator: validate_DescribeCluster_21626115, base: "/",
    makeUrl: url_DescribeCluster_21626116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_21626128 = ref object of OpenApiRestCall_21625437
proc url_DeleteCluster_21626130(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_21626129(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the cluster to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626131 = path.getOrDefault("name")
  valid_21626131 = validateParameter(valid_21626131, JString, required = true,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "name", valid_21626131
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
  var valid_21626132 = header.getOrDefault("X-Amz-Date")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Date", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Security-Token", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Algorithm", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Signature")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Signature", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Credential")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Credential", valid_21626138
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626139: Call_DeleteCluster_21626128; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ## 
  let valid = call_21626139.validator(path, query, header, formData, body, _)
  let scheme = call_21626139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626139.makeUrl(scheme.get, call_21626139.host, call_21626139.base,
                               call_21626139.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626139, uri, valid, _)

proc call*(call_21626140: Call_DeleteCluster_21626128; name: string): Recallable =
  ## deleteCluster
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ##   name: string (required)
  ##       : The name of the cluster to delete.
  var path_21626141 = newJObject()
  add(path_21626141, "name", newJString(name))
  result = call_21626140.call(path_21626141, nil, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_21626128(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}", validator: validate_DeleteCluster_21626129,
    base: "/", makeUrl: url_DeleteCluster_21626130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFargateProfile_21626142 = ref object of OpenApiRestCall_21625437
proc url_DescribeFargateProfile_21626144(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_DescribeFargateProfile_21626143(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626145 = path.getOrDefault("name")
  valid_21626145 = validateParameter(valid_21626145, JString, required = true,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "name", valid_21626145
  var valid_21626146 = path.getOrDefault("fargateProfileName")
  valid_21626146 = validateParameter(valid_21626146, JString, required = true,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "fargateProfileName", valid_21626146
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
  var valid_21626147 = header.getOrDefault("X-Amz-Date")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Date", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Security-Token", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Algorithm", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Signature")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Signature", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Credential")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Credential", valid_21626153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626154: Call_DescribeFargateProfile_21626142;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns descriptive information about an AWS Fargate profile.
  ## 
  let valid = call_21626154.validator(path, query, header, formData, body, _)
  let scheme = call_21626154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626154.makeUrl(scheme.get, call_21626154.host, call_21626154.base,
                               call_21626154.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626154, uri, valid, _)

proc call*(call_21626155: Call_DescribeFargateProfile_21626142; name: string;
          fargateProfileName: string): Recallable =
  ## describeFargateProfile
  ## Returns descriptive information about an AWS Fargate profile.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile.
  ##   fargateProfileName: string (required)
  ##                     : The name of the Fargate profile to describe.
  var path_21626156 = newJObject()
  add(path_21626156, "name", newJString(name))
  add(path_21626156, "fargateProfileName", newJString(fargateProfileName))
  result = call_21626155.call(path_21626156, nil, nil, nil, nil)

var describeFargateProfile* = Call_DescribeFargateProfile_21626142(
    name: "describeFargateProfile", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DescribeFargateProfile_21626143, base: "/",
    makeUrl: url_DescribeFargateProfile_21626144,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFargateProfile_21626157 = ref object of OpenApiRestCall_21625437
proc url_DeleteFargateProfile_21626159(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFargateProfile_21626158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626160 = path.getOrDefault("name")
  valid_21626160 = validateParameter(valid_21626160, JString, required = true,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "name", valid_21626160
  var valid_21626161 = path.getOrDefault("fargateProfileName")
  valid_21626161 = validateParameter(valid_21626161, JString, required = true,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "fargateProfileName", valid_21626161
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
  var valid_21626162 = header.getOrDefault("X-Amz-Date")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Date", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Security-Token", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Algorithm", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-Signature")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Signature", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Credential")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Credential", valid_21626168
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626169: Call_DeleteFargateProfile_21626157; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ## 
  let valid = call_21626169.validator(path, query, header, formData, body, _)
  let scheme = call_21626169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626169.makeUrl(scheme.get, call_21626169.host, call_21626169.base,
                               call_21626169.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626169, uri, valid, _)

proc call*(call_21626170: Call_DeleteFargateProfile_21626157; name: string;
          fargateProfileName: string): Recallable =
  ## deleteFargateProfile
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile to delete.
  ##   fargateProfileName: string (required)
  ##                     : The name of the Fargate profile to delete.
  var path_21626171 = newJObject()
  add(path_21626171, "name", newJString(name))
  add(path_21626171, "fargateProfileName", newJString(fargateProfileName))
  result = call_21626170.call(path_21626171, nil, nil, nil, nil)

var deleteFargateProfile* = Call_DeleteFargateProfile_21626157(
    name: "deleteFargateProfile", meth: HttpMethod.HttpDelete,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DeleteFargateProfile_21626158, base: "/",
    makeUrl: url_DeleteFargateProfile_21626159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodegroup_21626172 = ref object of OpenApiRestCall_21625437
proc url_DescribeNodegroup_21626174(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeNodegroup_21626173(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626175 = path.getOrDefault("name")
  valid_21626175 = validateParameter(valid_21626175, JString, required = true,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "name", valid_21626175
  var valid_21626176 = path.getOrDefault("nodegroupName")
  valid_21626176 = validateParameter(valid_21626176, JString, required = true,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "nodegroupName", valid_21626176
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
  var valid_21626177 = header.getOrDefault("X-Amz-Date")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Date", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Security-Token", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Algorithm", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Signature")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Signature", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Credential")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Credential", valid_21626183
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626184: Call_DescribeNodegroup_21626172; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns descriptive information about an Amazon EKS node group.
  ## 
  let valid = call_21626184.validator(path, query, header, formData, body, _)
  let scheme = call_21626184.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626184.makeUrl(scheme.get, call_21626184.host, call_21626184.base,
                               call_21626184.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626184, uri, valid, _)

proc call*(call_21626185: Call_DescribeNodegroup_21626172; name: string;
          nodegroupName: string): Recallable =
  ## describeNodegroup
  ## Returns descriptive information about an Amazon EKS node group.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to describe.
  var path_21626186 = newJObject()
  add(path_21626186, "name", newJString(name))
  add(path_21626186, "nodegroupName", newJString(nodegroupName))
  result = call_21626185.call(path_21626186, nil, nil, nil, nil)

var describeNodegroup* = Call_DescribeNodegroup_21626172(name: "describeNodegroup",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DescribeNodegroup_21626173, base: "/",
    makeUrl: url_DescribeNodegroup_21626174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNodegroup_21626187 = ref object of OpenApiRestCall_21625437
proc url_DeleteNodegroup_21626189(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteNodegroup_21626188(path: JsonNode; query: JsonNode;
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
  ##   nodegroupName: JString (required)
  ##                : The name of the node group to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626190 = path.getOrDefault("name")
  valid_21626190 = validateParameter(valid_21626190, JString, required = true,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "name", valid_21626190
  var valid_21626191 = path.getOrDefault("nodegroupName")
  valid_21626191 = validateParameter(valid_21626191, JString, required = true,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "nodegroupName", valid_21626191
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
  var valid_21626192 = header.getOrDefault("X-Amz-Date")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Date", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Security-Token", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Algorithm", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-Signature")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-Signature", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626197
  var valid_21626198 = header.getOrDefault("X-Amz-Credential")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Credential", valid_21626198
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626199: Call_DeleteNodegroup_21626187; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Amazon EKS node group for a cluster.
  ## 
  let valid = call_21626199.validator(path, query, header, formData, body, _)
  let scheme = call_21626199.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626199.makeUrl(scheme.get, call_21626199.host, call_21626199.base,
                               call_21626199.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626199, uri, valid, _)

proc call*(call_21626200: Call_DeleteNodegroup_21626187; name: string;
          nodegroupName: string): Recallable =
  ## deleteNodegroup
  ## Deletes an Amazon EKS node group for a cluster.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with your node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to delete.
  var path_21626201 = newJObject()
  add(path_21626201, "name", newJString(name))
  add(path_21626201, "nodegroupName", newJString(nodegroupName))
  result = call_21626200.call(path_21626201, nil, nil, nil, nil)

var deleteNodegroup* = Call_DeleteNodegroup_21626187(name: "deleteNodegroup",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DeleteNodegroup_21626188, base: "/",
    makeUrl: url_DeleteNodegroup_21626189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUpdate_21626202 = ref object of OpenApiRestCall_21625437
proc url_DescribeUpdate_21626204(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUpdate_21626203(path: JsonNode; query: JsonNode;
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
  ##   updateId: JString (required)
  ##           : The ID of the update to describe.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_21626205 = path.getOrDefault("name")
  valid_21626205 = validateParameter(valid_21626205, JString, required = true,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "name", valid_21626205
  var valid_21626206 = path.getOrDefault("updateId")
  valid_21626206 = validateParameter(valid_21626206, JString, required = true,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "updateId", valid_21626206
  result.add "path", section
  ## parameters in `query` object:
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS node group associated with the update.
  section = newJObject()
  var valid_21626207 = query.getOrDefault("nodegroupName")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "nodegroupName", valid_21626207
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
  var valid_21626208 = header.getOrDefault("X-Amz-Date")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Date", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Security-Token", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Algorithm", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Signature")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Signature", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Credential")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Credential", valid_21626214
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626215: Call_DescribeUpdate_21626202; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ## 
  let valid = call_21626215.validator(path, query, header, formData, body, _)
  let scheme = call_21626215.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626215.makeUrl(scheme.get, call_21626215.host, call_21626215.base,
                               call_21626215.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626215, uri, valid, _)

proc call*(call_21626216: Call_DescribeUpdate_21626202; name: string;
          updateId: string; nodegroupName: string = ""): Recallable =
  ## describeUpdate
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ##   nodegroupName: string
  ##                : The name of the Amazon EKS node group associated with the update.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the update.
  ##   updateId: string (required)
  ##           : The ID of the update to describe.
  var path_21626217 = newJObject()
  var query_21626218 = newJObject()
  add(query_21626218, "nodegroupName", newJString(nodegroupName))
  add(path_21626217, "name", newJString(name))
  add(path_21626217, "updateId", newJString(updateId))
  result = call_21626216.call(path_21626217, query_21626218, nil, nil, nil)

var describeUpdate* = Call_DescribeUpdate_21626202(name: "describeUpdate",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/updates/{updateId}",
    validator: validate_DescribeUpdate_21626203, base: "/",
    makeUrl: url_DescribeUpdate_21626204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626233 = ref object of OpenApiRestCall_21625437
proc url_TagResource_21626235(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626234(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626236 = path.getOrDefault("resourceArn")
  valid_21626236 = validateParameter(valid_21626236, JString, required = true,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "resourceArn", valid_21626236
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
  var valid_21626237 = header.getOrDefault("X-Amz-Date")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Date", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-Security-Token", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626239
  var valid_21626240 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626240 = validateParameter(valid_21626240, JString, required = false,
                                   default = nil)
  if valid_21626240 != nil:
    section.add "X-Amz-Algorithm", valid_21626240
  var valid_21626241 = header.getOrDefault("X-Amz-Signature")
  valid_21626241 = validateParameter(valid_21626241, JString, required = false,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "X-Amz-Signature", valid_21626241
  var valid_21626242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626242 = validateParameter(valid_21626242, JString, required = false,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626242
  var valid_21626243 = header.getOrDefault("X-Amz-Credential")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Credential", valid_21626243
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

proc call*(call_21626245: Call_TagResource_21626233; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ## 
  let valid = call_21626245.validator(path, query, header, formData, body, _)
  let scheme = call_21626245.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626245.makeUrl(scheme.get, call_21626245.host, call_21626245.base,
                               call_21626245.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626245, uri, valid, _)

proc call*(call_21626246: Call_TagResource_21626233; body: JsonNode;
          resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ##   body: JObject (required)
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to which to add tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_21626247 = newJObject()
  var body_21626248 = newJObject()
  if body != nil:
    body_21626248 = body
  add(path_21626247, "resourceArn", newJString(resourceArn))
  result = call_21626246.call(path_21626247, nil, nil, nil, body_21626248)

var tagResource* = Call_TagResource_21626233(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_21626234,
    base: "/", makeUrl: url_TagResource_21626235,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626219 = ref object of OpenApiRestCall_21625437
proc url_ListTagsForResource_21626221(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626220(path: JsonNode; query: JsonNode;
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
  var valid_21626222 = path.getOrDefault("resourceArn")
  valid_21626222 = validateParameter(valid_21626222, JString, required = true,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "resourceArn", valid_21626222
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
  var valid_21626223 = header.getOrDefault("X-Amz-Date")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Date", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-Security-Token", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Algorithm", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Signature")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Signature", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-Credential")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Credential", valid_21626229
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626230: Call_ListTagsForResource_21626219; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the tags for an Amazon EKS resource.
  ## 
  let valid = call_21626230.validator(path, query, header, formData, body, _)
  let scheme = call_21626230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626230.makeUrl(scheme.get, call_21626230.host, call_21626230.base,
                               call_21626230.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626230, uri, valid, _)

proc call*(call_21626231: Call_ListTagsForResource_21626219; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon EKS resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_21626232 = newJObject()
  add(path_21626232, "resourceArn", newJString(resourceArn))
  result = call_21626231.call(path_21626232, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626219(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_21626220, base: "/",
    makeUrl: url_ListTagsForResource_21626221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterVersion_21626267 = ref object of OpenApiRestCall_21625437
proc url_UpdateClusterVersion_21626269(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterVersion_21626268(path: JsonNode; query: JsonNode;
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
  var valid_21626270 = path.getOrDefault("name")
  valid_21626270 = validateParameter(valid_21626270, JString, required = true,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "name", valid_21626270
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
  var valid_21626271 = header.getOrDefault("X-Amz-Date")
  valid_21626271 = validateParameter(valid_21626271, JString, required = false,
                                   default = nil)
  if valid_21626271 != nil:
    section.add "X-Amz-Date", valid_21626271
  var valid_21626272 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626272 = validateParameter(valid_21626272, JString, required = false,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "X-Amz-Security-Token", valid_21626272
  var valid_21626273 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Algorithm", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Signature")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Signature", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Credential")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Credential", valid_21626277
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

proc call*(call_21626279: Call_UpdateClusterVersion_21626267; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ## 
  let valid = call_21626279.validator(path, query, header, formData, body, _)
  let scheme = call_21626279.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626279.makeUrl(scheme.get, call_21626279.host, call_21626279.base,
                               call_21626279.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626279, uri, valid, _)

proc call*(call_21626280: Call_UpdateClusterVersion_21626267; name: string;
          body: JsonNode): Recallable =
  ## updateClusterVersion
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_21626281 = newJObject()
  var body_21626282 = newJObject()
  add(path_21626281, "name", newJString(name))
  if body != nil:
    body_21626282 = body
  result = call_21626280.call(path_21626281, nil, nil, nil, body_21626282)

var updateClusterVersion* = Call_UpdateClusterVersion_21626267(
    name: "updateClusterVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/updates",
    validator: validate_UpdateClusterVersion_21626268, base: "/",
    makeUrl: url_UpdateClusterVersion_21626269,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUpdates_21626249 = ref object of OpenApiRestCall_21625437
proc url_ListUpdates_21626251(protocol: Scheme; host: string; base: string;
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

proc validate_ListUpdates_21626250(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
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
  var valid_21626252 = path.getOrDefault("name")
  valid_21626252 = validateParameter(valid_21626252, JString, required = true,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "name", valid_21626252
  result.add "path", section
  ## parameters in `query` object:
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS managed node group to list updates for.
  ##   maxResults: JInt
  ##             : The maximum number of update results returned by <code>ListUpdates</code> in paginated output. When you use this parameter, <code>ListUpdates</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListUpdates</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListUpdates</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListUpdates</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  section = newJObject()
  var valid_21626253 = query.getOrDefault("nodegroupName")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "nodegroupName", valid_21626253
  var valid_21626254 = query.getOrDefault("maxResults")
  valid_21626254 = validateParameter(valid_21626254, JInt, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "maxResults", valid_21626254
  var valid_21626255 = query.getOrDefault("nextToken")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "nextToken", valid_21626255
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
  var valid_21626256 = header.getOrDefault("X-Amz-Date")
  valid_21626256 = validateParameter(valid_21626256, JString, required = false,
                                   default = nil)
  if valid_21626256 != nil:
    section.add "X-Amz-Date", valid_21626256
  var valid_21626257 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626257 = validateParameter(valid_21626257, JString, required = false,
                                   default = nil)
  if valid_21626257 != nil:
    section.add "X-Amz-Security-Token", valid_21626257
  var valid_21626258 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Algorithm", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Signature")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Signature", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Credential")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Credential", valid_21626262
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626263: Call_ListUpdates_21626249; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
  ## 
  let valid = call_21626263.validator(path, query, header, formData, body, _)
  let scheme = call_21626263.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626263.makeUrl(scheme.get, call_21626263.host, call_21626263.base,
                               call_21626263.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626263, uri, valid, _)

proc call*(call_21626264: Call_ListUpdates_21626249; name: string;
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
  var path_21626265 = newJObject()
  var query_21626266 = newJObject()
  add(query_21626266, "nodegroupName", newJString(nodegroupName))
  add(path_21626265, "name", newJString(name))
  add(query_21626266, "maxResults", newJInt(maxResults))
  add(query_21626266, "nextToken", newJString(nextToken))
  result = call_21626264.call(path_21626265, query_21626266, nil, nil, nil)

var listUpdates* = Call_ListUpdates_21626249(name: "listUpdates",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/updates", validator: validate_ListUpdates_21626250,
    base: "/", makeUrl: url_ListUpdates_21626251,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626283 = ref object of OpenApiRestCall_21625437
proc url_UntagResource_21626285(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626284(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626286 = path.getOrDefault("resourceArn")
  valid_21626286 = validateParameter(valid_21626286, JString, required = true,
                                   default = nil)
  if valid_21626286 != nil:
    section.add "resourceArn", valid_21626286
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626287 = query.getOrDefault("tagKeys")
  valid_21626287 = validateParameter(valid_21626287, JArray, required = true,
                                   default = nil)
  if valid_21626287 != nil:
    section.add "tagKeys", valid_21626287
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
  var valid_21626288 = header.getOrDefault("X-Amz-Date")
  valid_21626288 = validateParameter(valid_21626288, JString, required = false,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "X-Amz-Date", valid_21626288
  var valid_21626289 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Security-Token", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Algorithm", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Signature")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Signature", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Credential")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Credential", valid_21626294
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626295: Call_UntagResource_21626283; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_21626295.validator(path, query, header, formData, body, _)
  let scheme = call_21626295.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626295.makeUrl(scheme.get, call_21626295.host, call_21626295.base,
                               call_21626295.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626295, uri, valid, _)

proc call*(call_21626296: Call_UntagResource_21626283; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource from which to delete tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_21626297 = newJObject()
  var query_21626298 = newJObject()
  if tagKeys != nil:
    query_21626298.add "tagKeys", tagKeys
  add(path_21626297, "resourceArn", newJString(resourceArn))
  result = call_21626296.call(path_21626297, query_21626298, nil, nil, nil)

var untagResource* = Call_UntagResource_21626283(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_21626284,
    base: "/", makeUrl: url_UntagResource_21626285,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfig_21626299 = ref object of OpenApiRestCall_21625437
proc url_UpdateClusterConfig_21626301(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateClusterConfig_21626300(path: JsonNode; query: JsonNode;
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
  var valid_21626302 = path.getOrDefault("name")
  valid_21626302 = validateParameter(valid_21626302, JString, required = true,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "name", valid_21626302
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
  var valid_21626303 = header.getOrDefault("X-Amz-Date")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Date", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Security-Token", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
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

proc call*(call_21626311: Call_UpdateClusterConfig_21626299; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ## 
  let valid = call_21626311.validator(path, query, header, formData, body, _)
  let scheme = call_21626311.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626311.makeUrl(scheme.get, call_21626311.host, call_21626311.base,
                               call_21626311.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626311, uri, valid, _)

proc call*(call_21626312: Call_UpdateClusterConfig_21626299; name: string;
          body: JsonNode): Recallable =
  ## updateClusterConfig
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_21626313 = newJObject()
  var body_21626314 = newJObject()
  add(path_21626313, "name", newJString(name))
  if body != nil:
    body_21626314 = body
  result = call_21626312.call(path_21626313, nil, nil, nil, body_21626314)

var updateClusterConfig* = Call_UpdateClusterConfig_21626299(
    name: "updateClusterConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/update-config",
    validator: validate_UpdateClusterConfig_21626300, base: "/",
    makeUrl: url_UpdateClusterConfig_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupConfig_21626315 = ref object of OpenApiRestCall_21625437
proc url_UpdateNodegroupConfig_21626317(protocol: Scheme; host: string; base: string;
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
               (kind: VariableSegment, value: "nodegroupName"),
               (kind: ConstantSegment, value: "/update-config")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateNodegroupConfig_21626316(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626318 = path.getOrDefault("name")
  valid_21626318 = validateParameter(valid_21626318, JString, required = true,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "name", valid_21626318
  var valid_21626319 = path.getOrDefault("nodegroupName")
  valid_21626319 = validateParameter(valid_21626319, JString, required = true,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "nodegroupName", valid_21626319
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
  var valid_21626320 = header.getOrDefault("X-Amz-Date")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Date", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Security-Token", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Algorithm", valid_21626323
  var valid_21626324 = header.getOrDefault("X-Amz-Signature")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Signature", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Credential")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Credential", valid_21626326
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

proc call*(call_21626328: Call_UpdateNodegroupConfig_21626315;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ## 
  let valid = call_21626328.validator(path, query, header, formData, body, _)
  let scheme = call_21626328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626328.makeUrl(scheme.get, call_21626328.host, call_21626328.base,
                               call_21626328.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626328, uri, valid, _)

proc call*(call_21626329: Call_UpdateNodegroupConfig_21626315; name: string;
          nodegroupName: string; body: JsonNode): Recallable =
  ## updateNodegroupConfig
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that the managed node group resides in.
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  ##   body: JObject (required)
  var path_21626330 = newJObject()
  var body_21626331 = newJObject()
  add(path_21626330, "name", newJString(name))
  add(path_21626330, "nodegroupName", newJString(nodegroupName))
  if body != nil:
    body_21626331 = body
  result = call_21626329.call(path_21626330, nil, nil, nil, body_21626331)

var updateNodegroupConfig* = Call_UpdateNodegroupConfig_21626315(
    name: "updateNodegroupConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-config",
    validator: validate_UpdateNodegroupConfig_21626316, base: "/",
    makeUrl: url_UpdateNodegroupConfig_21626317,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupVersion_21626332 = ref object of OpenApiRestCall_21625437
proc url_UpdateNodegroupVersion_21626334(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
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
               (kind: VariableSegment, value: "nodegroupName"),
               (kind: ConstantSegment, value: "/update-version")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateNodegroupVersion_21626333(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626335 = path.getOrDefault("name")
  valid_21626335 = validateParameter(valid_21626335, JString, required = true,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "name", valid_21626335
  var valid_21626336 = path.getOrDefault("nodegroupName")
  valid_21626336 = validateParameter(valid_21626336, JString, required = true,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "nodegroupName", valid_21626336
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
  var valid_21626337 = header.getOrDefault("X-Amz-Date")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Date", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-Security-Token", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626339
  var valid_21626340 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626340 = validateParameter(valid_21626340, JString, required = false,
                                   default = nil)
  if valid_21626340 != nil:
    section.add "X-Amz-Algorithm", valid_21626340
  var valid_21626341 = header.getOrDefault("X-Amz-Signature")
  valid_21626341 = validateParameter(valid_21626341, JString, required = false,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "X-Amz-Signature", valid_21626341
  var valid_21626342 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626342 = validateParameter(valid_21626342, JString, required = false,
                                   default = nil)
  if valid_21626342 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626342
  var valid_21626343 = header.getOrDefault("X-Amz-Credential")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Credential", valid_21626343
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

proc call*(call_21626345: Call_UpdateNodegroupVersion_21626332;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ## 
  let valid = call_21626345.validator(path, query, header, formData, body, _)
  let scheme = call_21626345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626345.makeUrl(scheme.get, call_21626345.host, call_21626345.base,
                               call_21626345.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626345, uri, valid, _)

proc call*(call_21626346: Call_UpdateNodegroupVersion_21626332; name: string;
          nodegroupName: string; body: JsonNode): Recallable =
  ## updateNodegroupVersion
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with the managed node group to update.
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  ##   body: JObject (required)
  var path_21626347 = newJObject()
  var body_21626348 = newJObject()
  add(path_21626347, "name", newJString(name))
  add(path_21626347, "nodegroupName", newJString(nodegroupName))
  if body != nil:
    body_21626348 = body
  result = call_21626346.call(path_21626347, nil, nil, nil, body_21626348)

var updateNodegroupVersion* = Call_UpdateNodegroupVersion_21626332(
    name: "updateNodegroupVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-version",
    validator: validate_UpdateNodegroupVersion_21626333, base: "/",
    makeUrl: url_UpdateNodegroupVersion_21626334,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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