
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

  OpenApiRestCall_597390 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597390](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597390): Option[Scheme] {.used.} =
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
  Call_CreateCluster_597985 = ref object of OpenApiRestCall_597390
proc url_CreateCluster_597987(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCluster_597986(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597988 = header.getOrDefault("X-Amz-Signature")
  valid_597988 = validateParameter(valid_597988, JString, required = false,
                                 default = nil)
  if valid_597988 != nil:
    section.add "X-Amz-Signature", valid_597988
  var valid_597989 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597989 = validateParameter(valid_597989, JString, required = false,
                                 default = nil)
  if valid_597989 != nil:
    section.add "X-Amz-Content-Sha256", valid_597989
  var valid_597990 = header.getOrDefault("X-Amz-Date")
  valid_597990 = validateParameter(valid_597990, JString, required = false,
                                 default = nil)
  if valid_597990 != nil:
    section.add "X-Amz-Date", valid_597990
  var valid_597991 = header.getOrDefault("X-Amz-Credential")
  valid_597991 = validateParameter(valid_597991, JString, required = false,
                                 default = nil)
  if valid_597991 != nil:
    section.add "X-Amz-Credential", valid_597991
  var valid_597992 = header.getOrDefault("X-Amz-Security-Token")
  valid_597992 = validateParameter(valid_597992, JString, required = false,
                                 default = nil)
  if valid_597992 != nil:
    section.add "X-Amz-Security-Token", valid_597992
  var valid_597993 = header.getOrDefault("X-Amz-Algorithm")
  valid_597993 = validateParameter(valid_597993, JString, required = false,
                                 default = nil)
  if valid_597993 != nil:
    section.add "X-Amz-Algorithm", valid_597993
  var valid_597994 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597994 = validateParameter(valid_597994, JString, required = false,
                                 default = nil)
  if valid_597994 != nil:
    section.add "X-Amz-SignedHeaders", valid_597994
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597996: Call_CreateCluster_597985; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  let valid = call_597996.validator(path, query, header, formData, body)
  let scheme = call_597996.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597996.url(scheme.get, call_597996.host, call_597996.base,
                         call_597996.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597996, url, valid)

proc call*(call_597997: Call_CreateCluster_597985; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   body: JObject (required)
  var body_597998 = newJObject()
  if body != nil:
    body_597998 = body
  result = call_597997.call(nil, nil, nil, nil, body_597998)

var createCluster* = Call_CreateCluster_597985(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_CreateCluster_597986, base: "/", url: url_CreateCluster_597987,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_597728 = ref object of OpenApiRestCall_597390
proc url_ListClusters_597730(protocol: Scheme; host: string; base: string;
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

proc validate_ListClusters_597729(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597842 = query.getOrDefault("nextToken")
  valid_597842 = validateParameter(valid_597842, JString, required = false,
                                 default = nil)
  if valid_597842 != nil:
    section.add "nextToken", valid_597842
  var valid_597843 = query.getOrDefault("maxResults")
  valid_597843 = validateParameter(valid_597843, JInt, required = false, default = nil)
  if valid_597843 != nil:
    section.add "maxResults", valid_597843
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
  var valid_597844 = header.getOrDefault("X-Amz-Signature")
  valid_597844 = validateParameter(valid_597844, JString, required = false,
                                 default = nil)
  if valid_597844 != nil:
    section.add "X-Amz-Signature", valid_597844
  var valid_597845 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597845 = validateParameter(valid_597845, JString, required = false,
                                 default = nil)
  if valid_597845 != nil:
    section.add "X-Amz-Content-Sha256", valid_597845
  var valid_597846 = header.getOrDefault("X-Amz-Date")
  valid_597846 = validateParameter(valid_597846, JString, required = false,
                                 default = nil)
  if valid_597846 != nil:
    section.add "X-Amz-Date", valid_597846
  var valid_597847 = header.getOrDefault("X-Amz-Credential")
  valid_597847 = validateParameter(valid_597847, JString, required = false,
                                 default = nil)
  if valid_597847 != nil:
    section.add "X-Amz-Credential", valid_597847
  var valid_597848 = header.getOrDefault("X-Amz-Security-Token")
  valid_597848 = validateParameter(valid_597848, JString, required = false,
                                 default = nil)
  if valid_597848 != nil:
    section.add "X-Amz-Security-Token", valid_597848
  var valid_597849 = header.getOrDefault("X-Amz-Algorithm")
  valid_597849 = validateParameter(valid_597849, JString, required = false,
                                 default = nil)
  if valid_597849 != nil:
    section.add "X-Amz-Algorithm", valid_597849
  var valid_597850 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597850 = validateParameter(valid_597850, JString, required = false,
                                 default = nil)
  if valid_597850 != nil:
    section.add "X-Amz-SignedHeaders", valid_597850
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597873: Call_ListClusters_597728; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ## 
  let valid = call_597873.validator(path, query, header, formData, body)
  let scheme = call_597873.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597873.url(scheme.get, call_597873.host, call_597873.base,
                         call_597873.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597873, url, valid)

proc call*(call_597944: Call_ListClusters_597728; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listClusters
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ##   nextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListClusters</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.</p> <note> <p>This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  ##   maxResults: int
  ##             : The maximum number of cluster results returned by <code>ListClusters</code> in paginated output. When you use this parameter, <code>ListClusters</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListClusters</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListClusters</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var query_597945 = newJObject()
  add(query_597945, "nextToken", newJString(nextToken))
  add(query_597945, "maxResults", newJInt(maxResults))
  result = call_597944.call(nil, query_597945, nil, nil, nil)

var listClusters* = Call_ListClusters_597728(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_ListClusters_597729, base: "/", url: url_ListClusters_597730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFargateProfile_598030 = ref object of OpenApiRestCall_597390
proc url_CreateFargateProfile_598032(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFargateProfile_598031(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to schedule pods on Fargate infrastructure.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate infrastructure and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate infrastructure. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is scheduled on Fargate infrastructure.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster. This role is what allows Fargate infrastructure to appear in your cluster as nodes. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   name: JString (required)
  ##       : The name of the Amazon EKS cluster to apply the Fargate profile to.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `name` field"
  var valid_598033 = path.getOrDefault("name")
  valid_598033 = validateParameter(valid_598033, JString, required = true,
                                 default = nil)
  if valid_598033 != nil:
    section.add "name", valid_598033
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
  var valid_598034 = header.getOrDefault("X-Amz-Signature")
  valid_598034 = validateParameter(valid_598034, JString, required = false,
                                 default = nil)
  if valid_598034 != nil:
    section.add "X-Amz-Signature", valid_598034
  var valid_598035 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598035 = validateParameter(valid_598035, JString, required = false,
                                 default = nil)
  if valid_598035 != nil:
    section.add "X-Amz-Content-Sha256", valid_598035
  var valid_598036 = header.getOrDefault("X-Amz-Date")
  valid_598036 = validateParameter(valid_598036, JString, required = false,
                                 default = nil)
  if valid_598036 != nil:
    section.add "X-Amz-Date", valid_598036
  var valid_598037 = header.getOrDefault("X-Amz-Credential")
  valid_598037 = validateParameter(valid_598037, JString, required = false,
                                 default = nil)
  if valid_598037 != nil:
    section.add "X-Amz-Credential", valid_598037
  var valid_598038 = header.getOrDefault("X-Amz-Security-Token")
  valid_598038 = validateParameter(valid_598038, JString, required = false,
                                 default = nil)
  if valid_598038 != nil:
    section.add "X-Amz-Security-Token", valid_598038
  var valid_598039 = header.getOrDefault("X-Amz-Algorithm")
  valid_598039 = validateParameter(valid_598039, JString, required = false,
                                 default = nil)
  if valid_598039 != nil:
    section.add "X-Amz-Algorithm", valid_598039
  var valid_598040 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598040 = validateParameter(valid_598040, JString, required = false,
                                 default = nil)
  if valid_598040 != nil:
    section.add "X-Amz-SignedHeaders", valid_598040
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598042: Call_CreateFargateProfile_598030; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to schedule pods on Fargate infrastructure.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate infrastructure and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate infrastructure. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is scheduled on Fargate infrastructure.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster. This role is what allows Fargate infrastructure to appear in your cluster as nodes. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  let valid = call_598042.validator(path, query, header, formData, body)
  let scheme = call_598042.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598042.url(scheme.get, call_598042.host, call_598042.base,
                         call_598042.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598042, url, valid)

proc call*(call_598043: Call_CreateFargateProfile_598030; name: string;
          body: JsonNode): Recallable =
  ## createFargateProfile
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to schedule pods on Fargate infrastructure.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate infrastructure and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate infrastructure. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is scheduled on Fargate infrastructure.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster. This role is what allows Fargate infrastructure to appear in your cluster as nodes. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to apply the Fargate profile to.
  ##   body: JObject (required)
  var path_598044 = newJObject()
  var body_598045 = newJObject()
  add(path_598044, "name", newJString(name))
  if body != nil:
    body_598045 = body
  result = call_598043.call(path_598044, nil, nil, nil, body_598045)

var createFargateProfile* = Call_CreateFargateProfile_598030(
    name: "createFargateProfile", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_CreateFargateProfile_598031, base: "/",
    url: url_CreateFargateProfile_598032, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFargateProfiles_597999 = ref object of OpenApiRestCall_597390
proc url_ListFargateProfiles_598001(protocol: Scheme; host: string; base: string;
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

proc validate_ListFargateProfiles_598000(path: JsonNode; query: JsonNode;
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
  var valid_598016 = path.getOrDefault("name")
  valid_598016 = validateParameter(valid_598016, JString, required = true,
                                 default = nil)
  if valid_598016 != nil:
    section.add "name", valid_598016
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListFargateProfiles</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   maxResults: JInt
  ##             : The maximum number of Fargate profile results returned by <code>ListFargateProfiles</code> in paginated output. When you use this parameter, <code>ListFargateProfiles</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListFargateProfiles</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListFargateProfiles</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_598017 = query.getOrDefault("nextToken")
  valid_598017 = validateParameter(valid_598017, JString, required = false,
                                 default = nil)
  if valid_598017 != nil:
    section.add "nextToken", valid_598017
  var valid_598018 = query.getOrDefault("maxResults")
  valid_598018 = validateParameter(valid_598018, JInt, required = false, default = nil)
  if valid_598018 != nil:
    section.add "maxResults", valid_598018
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
  var valid_598019 = header.getOrDefault("X-Amz-Signature")
  valid_598019 = validateParameter(valid_598019, JString, required = false,
                                 default = nil)
  if valid_598019 != nil:
    section.add "X-Amz-Signature", valid_598019
  var valid_598020 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598020 = validateParameter(valid_598020, JString, required = false,
                                 default = nil)
  if valid_598020 != nil:
    section.add "X-Amz-Content-Sha256", valid_598020
  var valid_598021 = header.getOrDefault("X-Amz-Date")
  valid_598021 = validateParameter(valid_598021, JString, required = false,
                                 default = nil)
  if valid_598021 != nil:
    section.add "X-Amz-Date", valid_598021
  var valid_598022 = header.getOrDefault("X-Amz-Credential")
  valid_598022 = validateParameter(valid_598022, JString, required = false,
                                 default = nil)
  if valid_598022 != nil:
    section.add "X-Amz-Credential", valid_598022
  var valid_598023 = header.getOrDefault("X-Amz-Security-Token")
  valid_598023 = validateParameter(valid_598023, JString, required = false,
                                 default = nil)
  if valid_598023 != nil:
    section.add "X-Amz-Security-Token", valid_598023
  var valid_598024 = header.getOrDefault("X-Amz-Algorithm")
  valid_598024 = validateParameter(valid_598024, JString, required = false,
                                 default = nil)
  if valid_598024 != nil:
    section.add "X-Amz-Algorithm", valid_598024
  var valid_598025 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "X-Amz-SignedHeaders", valid_598025
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598026: Call_ListFargateProfiles_597999; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ## 
  let valid = call_598026.validator(path, query, header, formData, body)
  let scheme = call_598026.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598026.url(scheme.get, call_598026.host, call_598026.base,
                         call_598026.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598026, url, valid)

proc call*(call_598027: Call_ListFargateProfiles_597999; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listFargateProfiles
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListFargateProfiles</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that you would like to listFargate profiles in.
  ##   maxResults: int
  ##             : The maximum number of Fargate profile results returned by <code>ListFargateProfiles</code> in paginated output. When you use this parameter, <code>ListFargateProfiles</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListFargateProfiles</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListFargateProfiles</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var path_598028 = newJObject()
  var query_598029 = newJObject()
  add(query_598029, "nextToken", newJString(nextToken))
  add(path_598028, "name", newJString(name))
  add(query_598029, "maxResults", newJInt(maxResults))
  result = call_598027.call(path_598028, query_598029, nil, nil, nil)

var listFargateProfiles* = Call_ListFargateProfiles_597999(
    name: "listFargateProfiles", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_ListFargateProfiles_598000, base: "/",
    url: url_ListFargateProfiles_598001, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNodegroup_598063 = ref object of OpenApiRestCall_597390
proc url_CreateNodegroup_598065(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNodegroup_598064(path: JsonNode; query: JsonNode;
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
  var valid_598066 = path.getOrDefault("name")
  valid_598066 = validateParameter(valid_598066, JString, required = true,
                                 default = nil)
  if valid_598066 != nil:
    section.add "name", valid_598066
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
  var valid_598067 = header.getOrDefault("X-Amz-Signature")
  valid_598067 = validateParameter(valid_598067, JString, required = false,
                                 default = nil)
  if valid_598067 != nil:
    section.add "X-Amz-Signature", valid_598067
  var valid_598068 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598068 = validateParameter(valid_598068, JString, required = false,
                                 default = nil)
  if valid_598068 != nil:
    section.add "X-Amz-Content-Sha256", valid_598068
  var valid_598069 = header.getOrDefault("X-Amz-Date")
  valid_598069 = validateParameter(valid_598069, JString, required = false,
                                 default = nil)
  if valid_598069 != nil:
    section.add "X-Amz-Date", valid_598069
  var valid_598070 = header.getOrDefault("X-Amz-Credential")
  valid_598070 = validateParameter(valid_598070, JString, required = false,
                                 default = nil)
  if valid_598070 != nil:
    section.add "X-Amz-Credential", valid_598070
  var valid_598071 = header.getOrDefault("X-Amz-Security-Token")
  valid_598071 = validateParameter(valid_598071, JString, required = false,
                                 default = nil)
  if valid_598071 != nil:
    section.add "X-Amz-Security-Token", valid_598071
  var valid_598072 = header.getOrDefault("X-Amz-Algorithm")
  valid_598072 = validateParameter(valid_598072, JString, required = false,
                                 default = nil)
  if valid_598072 != nil:
    section.add "X-Amz-Algorithm", valid_598072
  var valid_598073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598073 = validateParameter(valid_598073, JString, required = false,
                                 default = nil)
  if valid_598073 != nil:
    section.add "X-Amz-SignedHeaders", valid_598073
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598075: Call_CreateNodegroup_598063; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ## 
  let valid = call_598075.validator(path, query, header, formData, body)
  let scheme = call_598075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598075.url(scheme.get, call_598075.host, call_598075.base,
                         call_598075.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598075, url, valid)

proc call*(call_598076: Call_CreateNodegroup_598063; name: string; body: JsonNode): Recallable =
  ## createNodegroup
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ##   name: string (required)
  ##       : The name of the cluster to create the node group in.
  ##   body: JObject (required)
  var path_598077 = newJObject()
  var body_598078 = newJObject()
  add(path_598077, "name", newJString(name))
  if body != nil:
    body_598078 = body
  result = call_598076.call(path_598077, nil, nil, nil, body_598078)

var createNodegroup* = Call_CreateNodegroup_598063(name: "createNodegroup",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_CreateNodegroup_598064,
    base: "/", url: url_CreateNodegroup_598065, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodegroups_598046 = ref object of OpenApiRestCall_597390
proc url_ListNodegroups_598048(protocol: Scheme; host: string; base: string;
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

proc validate_ListNodegroups_598047(path: JsonNode; query: JsonNode;
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
  var valid_598049 = path.getOrDefault("name")
  valid_598049 = validateParameter(valid_598049, JString, required = true,
                                 default = nil)
  if valid_598049 != nil:
    section.add "name", valid_598049
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   maxResults: JInt
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_598050 = query.getOrDefault("nextToken")
  valid_598050 = validateParameter(valid_598050, JString, required = false,
                                 default = nil)
  if valid_598050 != nil:
    section.add "nextToken", valid_598050
  var valid_598051 = query.getOrDefault("maxResults")
  valid_598051 = validateParameter(valid_598051, JInt, required = false, default = nil)
  if valid_598051 != nil:
    section.add "maxResults", valid_598051
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
  var valid_598052 = header.getOrDefault("X-Amz-Signature")
  valid_598052 = validateParameter(valid_598052, JString, required = false,
                                 default = nil)
  if valid_598052 != nil:
    section.add "X-Amz-Signature", valid_598052
  var valid_598053 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598053 = validateParameter(valid_598053, JString, required = false,
                                 default = nil)
  if valid_598053 != nil:
    section.add "X-Amz-Content-Sha256", valid_598053
  var valid_598054 = header.getOrDefault("X-Amz-Date")
  valid_598054 = validateParameter(valid_598054, JString, required = false,
                                 default = nil)
  if valid_598054 != nil:
    section.add "X-Amz-Date", valid_598054
  var valid_598055 = header.getOrDefault("X-Amz-Credential")
  valid_598055 = validateParameter(valid_598055, JString, required = false,
                                 default = nil)
  if valid_598055 != nil:
    section.add "X-Amz-Credential", valid_598055
  var valid_598056 = header.getOrDefault("X-Amz-Security-Token")
  valid_598056 = validateParameter(valid_598056, JString, required = false,
                                 default = nil)
  if valid_598056 != nil:
    section.add "X-Amz-Security-Token", valid_598056
  var valid_598057 = header.getOrDefault("X-Amz-Algorithm")
  valid_598057 = validateParameter(valid_598057, JString, required = false,
                                 default = nil)
  if valid_598057 != nil:
    section.add "X-Amz-Algorithm", valid_598057
  var valid_598058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598058 = validateParameter(valid_598058, JString, required = false,
                                 default = nil)
  if valid_598058 != nil:
    section.add "X-Amz-SignedHeaders", valid_598058
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598059: Call_ListNodegroups_598046; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ## 
  let valid = call_598059.validator(path, query, header, formData, body)
  let scheme = call_598059.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598059.url(scheme.get, call_598059.host, call_598059.base,
                         call_598059.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598059, url, valid)

proc call*(call_598060: Call_ListNodegroups_598046; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listNodegroups
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that you would like to list node groups in.
  ##   maxResults: int
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var path_598061 = newJObject()
  var query_598062 = newJObject()
  add(query_598062, "nextToken", newJString(nextToken))
  add(path_598061, "name", newJString(name))
  add(query_598062, "maxResults", newJInt(maxResults))
  result = call_598060.call(path_598061, query_598062, nil, nil, nil)

var listNodegroups* = Call_ListNodegroups_598046(name: "listNodegroups",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_ListNodegroups_598047,
    base: "/", url: url_ListNodegroups_598048, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_598079 = ref object of OpenApiRestCall_597390
proc url_DescribeCluster_598081(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCluster_598080(path: JsonNode; query: JsonNode;
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
  var valid_598082 = path.getOrDefault("name")
  valid_598082 = validateParameter(valid_598082, JString, required = true,
                                 default = nil)
  if valid_598082 != nil:
    section.add "name", valid_598082
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
  var valid_598083 = header.getOrDefault("X-Amz-Signature")
  valid_598083 = validateParameter(valid_598083, JString, required = false,
                                 default = nil)
  if valid_598083 != nil:
    section.add "X-Amz-Signature", valid_598083
  var valid_598084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598084 = validateParameter(valid_598084, JString, required = false,
                                 default = nil)
  if valid_598084 != nil:
    section.add "X-Amz-Content-Sha256", valid_598084
  var valid_598085 = header.getOrDefault("X-Amz-Date")
  valid_598085 = validateParameter(valid_598085, JString, required = false,
                                 default = nil)
  if valid_598085 != nil:
    section.add "X-Amz-Date", valid_598085
  var valid_598086 = header.getOrDefault("X-Amz-Credential")
  valid_598086 = validateParameter(valid_598086, JString, required = false,
                                 default = nil)
  if valid_598086 != nil:
    section.add "X-Amz-Credential", valid_598086
  var valid_598087 = header.getOrDefault("X-Amz-Security-Token")
  valid_598087 = validateParameter(valid_598087, JString, required = false,
                                 default = nil)
  if valid_598087 != nil:
    section.add "X-Amz-Security-Token", valid_598087
  var valid_598088 = header.getOrDefault("X-Amz-Algorithm")
  valid_598088 = validateParameter(valid_598088, JString, required = false,
                                 default = nil)
  if valid_598088 != nil:
    section.add "X-Amz-Algorithm", valid_598088
  var valid_598089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598089 = validateParameter(valid_598089, JString, required = false,
                                 default = nil)
  if valid_598089 != nil:
    section.add "X-Amz-SignedHeaders", valid_598089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598090: Call_DescribeCluster_598079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ## 
  let valid = call_598090.validator(path, query, header, formData, body)
  let scheme = call_598090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598090.url(scheme.get, call_598090.host, call_598090.base,
                         call_598090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598090, url, valid)

proc call*(call_598091: Call_DescribeCluster_598079; name: string): Recallable =
  ## describeCluster
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ##   name: string (required)
  ##       : The name of the cluster to describe.
  var path_598092 = newJObject()
  add(path_598092, "name", newJString(name))
  result = call_598091.call(path_598092, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_598079(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters/{name}",
    validator: validate_DescribeCluster_598080, base: "/", url: url_DescribeCluster_598081,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_598093 = ref object of OpenApiRestCall_597390
proc url_DeleteCluster_598095(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_598094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598096 = path.getOrDefault("name")
  valid_598096 = validateParameter(valid_598096, JString, required = true,
                                 default = nil)
  if valid_598096 != nil:
    section.add "name", valid_598096
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
  var valid_598097 = header.getOrDefault("X-Amz-Signature")
  valid_598097 = validateParameter(valid_598097, JString, required = false,
                                 default = nil)
  if valid_598097 != nil:
    section.add "X-Amz-Signature", valid_598097
  var valid_598098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598098 = validateParameter(valid_598098, JString, required = false,
                                 default = nil)
  if valid_598098 != nil:
    section.add "X-Amz-Content-Sha256", valid_598098
  var valid_598099 = header.getOrDefault("X-Amz-Date")
  valid_598099 = validateParameter(valid_598099, JString, required = false,
                                 default = nil)
  if valid_598099 != nil:
    section.add "X-Amz-Date", valid_598099
  var valid_598100 = header.getOrDefault("X-Amz-Credential")
  valid_598100 = validateParameter(valid_598100, JString, required = false,
                                 default = nil)
  if valid_598100 != nil:
    section.add "X-Amz-Credential", valid_598100
  var valid_598101 = header.getOrDefault("X-Amz-Security-Token")
  valid_598101 = validateParameter(valid_598101, JString, required = false,
                                 default = nil)
  if valid_598101 != nil:
    section.add "X-Amz-Security-Token", valid_598101
  var valid_598102 = header.getOrDefault("X-Amz-Algorithm")
  valid_598102 = validateParameter(valid_598102, JString, required = false,
                                 default = nil)
  if valid_598102 != nil:
    section.add "X-Amz-Algorithm", valid_598102
  var valid_598103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598103 = validateParameter(valid_598103, JString, required = false,
                                 default = nil)
  if valid_598103 != nil:
    section.add "X-Amz-SignedHeaders", valid_598103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598104: Call_DeleteCluster_598093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ## 
  let valid = call_598104.validator(path, query, header, formData, body)
  let scheme = call_598104.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598104.url(scheme.get, call_598104.host, call_598104.base,
                         call_598104.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598104, url, valid)

proc call*(call_598105: Call_DeleteCluster_598093; name: string): Recallable =
  ## deleteCluster
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ##   name: string (required)
  ##       : The name of the cluster to delete.
  var path_598106 = newJObject()
  add(path_598106, "name", newJString(name))
  result = call_598105.call(path_598106, nil, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_598093(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}", validator: validate_DeleteCluster_598094, base: "/",
    url: url_DeleteCluster_598095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFargateProfile_598107 = ref object of OpenApiRestCall_597390
proc url_DescribeFargateProfile_598109(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFargateProfile_598108(path: JsonNode; query: JsonNode;
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
  var valid_598110 = path.getOrDefault("name")
  valid_598110 = validateParameter(valid_598110, JString, required = true,
                                 default = nil)
  if valid_598110 != nil:
    section.add "name", valid_598110
  var valid_598111 = path.getOrDefault("fargateProfileName")
  valid_598111 = validateParameter(valid_598111, JString, required = true,
                                 default = nil)
  if valid_598111 != nil:
    section.add "fargateProfileName", valid_598111
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
  var valid_598112 = header.getOrDefault("X-Amz-Signature")
  valid_598112 = validateParameter(valid_598112, JString, required = false,
                                 default = nil)
  if valid_598112 != nil:
    section.add "X-Amz-Signature", valid_598112
  var valid_598113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598113 = validateParameter(valid_598113, JString, required = false,
                                 default = nil)
  if valid_598113 != nil:
    section.add "X-Amz-Content-Sha256", valid_598113
  var valid_598114 = header.getOrDefault("X-Amz-Date")
  valid_598114 = validateParameter(valid_598114, JString, required = false,
                                 default = nil)
  if valid_598114 != nil:
    section.add "X-Amz-Date", valid_598114
  var valid_598115 = header.getOrDefault("X-Amz-Credential")
  valid_598115 = validateParameter(valid_598115, JString, required = false,
                                 default = nil)
  if valid_598115 != nil:
    section.add "X-Amz-Credential", valid_598115
  var valid_598116 = header.getOrDefault("X-Amz-Security-Token")
  valid_598116 = validateParameter(valid_598116, JString, required = false,
                                 default = nil)
  if valid_598116 != nil:
    section.add "X-Amz-Security-Token", valid_598116
  var valid_598117 = header.getOrDefault("X-Amz-Algorithm")
  valid_598117 = validateParameter(valid_598117, JString, required = false,
                                 default = nil)
  if valid_598117 != nil:
    section.add "X-Amz-Algorithm", valid_598117
  var valid_598118 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598118 = validateParameter(valid_598118, JString, required = false,
                                 default = nil)
  if valid_598118 != nil:
    section.add "X-Amz-SignedHeaders", valid_598118
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598119: Call_DescribeFargateProfile_598107; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptive information about an AWS Fargate profile.
  ## 
  let valid = call_598119.validator(path, query, header, formData, body)
  let scheme = call_598119.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598119.url(scheme.get, call_598119.host, call_598119.base,
                         call_598119.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598119, url, valid)

proc call*(call_598120: Call_DescribeFargateProfile_598107; name: string;
          fargateProfileName: string): Recallable =
  ## describeFargateProfile
  ## Returns descriptive information about an AWS Fargate profile.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile.
  ##   fargateProfileName: string (required)
  ##                     : The name of the Fargate profile to describe.
  var path_598121 = newJObject()
  add(path_598121, "name", newJString(name))
  add(path_598121, "fargateProfileName", newJString(fargateProfileName))
  result = call_598120.call(path_598121, nil, nil, nil, nil)

var describeFargateProfile* = Call_DescribeFargateProfile_598107(
    name: "describeFargateProfile", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DescribeFargateProfile_598108, base: "/",
    url: url_DescribeFargateProfile_598109, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFargateProfile_598122 = ref object of OpenApiRestCall_597390
proc url_DeleteFargateProfile_598124(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFargateProfile_598123(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods that were scheduled onto Fargate infrastructure with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate infrastructure with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate infrastructure.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
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
  var valid_598125 = path.getOrDefault("name")
  valid_598125 = validateParameter(valid_598125, JString, required = true,
                                 default = nil)
  if valid_598125 != nil:
    section.add "name", valid_598125
  var valid_598126 = path.getOrDefault("fargateProfileName")
  valid_598126 = validateParameter(valid_598126, JString, required = true,
                                 default = nil)
  if valid_598126 != nil:
    section.add "fargateProfileName", valid_598126
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
  var valid_598127 = header.getOrDefault("X-Amz-Signature")
  valid_598127 = validateParameter(valid_598127, JString, required = false,
                                 default = nil)
  if valid_598127 != nil:
    section.add "X-Amz-Signature", valid_598127
  var valid_598128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598128 = validateParameter(valid_598128, JString, required = false,
                                 default = nil)
  if valid_598128 != nil:
    section.add "X-Amz-Content-Sha256", valid_598128
  var valid_598129 = header.getOrDefault("X-Amz-Date")
  valid_598129 = validateParameter(valid_598129, JString, required = false,
                                 default = nil)
  if valid_598129 != nil:
    section.add "X-Amz-Date", valid_598129
  var valid_598130 = header.getOrDefault("X-Amz-Credential")
  valid_598130 = validateParameter(valid_598130, JString, required = false,
                                 default = nil)
  if valid_598130 != nil:
    section.add "X-Amz-Credential", valid_598130
  var valid_598131 = header.getOrDefault("X-Amz-Security-Token")
  valid_598131 = validateParameter(valid_598131, JString, required = false,
                                 default = nil)
  if valid_598131 != nil:
    section.add "X-Amz-Security-Token", valid_598131
  var valid_598132 = header.getOrDefault("X-Amz-Algorithm")
  valid_598132 = validateParameter(valid_598132, JString, required = false,
                                 default = nil)
  if valid_598132 != nil:
    section.add "X-Amz-Algorithm", valid_598132
  var valid_598133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598133 = validateParameter(valid_598133, JString, required = false,
                                 default = nil)
  if valid_598133 != nil:
    section.add "X-Amz-SignedHeaders", valid_598133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598134: Call_DeleteFargateProfile_598122; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods that were scheduled onto Fargate infrastructure with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate infrastructure with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate infrastructure.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ## 
  let valid = call_598134.validator(path, query, header, formData, body)
  let scheme = call_598134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598134.url(scheme.get, call_598134.host, call_598134.base,
                         call_598134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598134, url, valid)

proc call*(call_598135: Call_DeleteFargateProfile_598122; name: string;
          fargateProfileName: string): Recallable =
  ## deleteFargateProfile
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods that were scheduled onto Fargate infrastructure with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate infrastructure with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate infrastructure.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile to delete.
  ##   fargateProfileName: string (required)
  ##                     : The name of the Fargate profile to delete.
  var path_598136 = newJObject()
  add(path_598136, "name", newJString(name))
  add(path_598136, "fargateProfileName", newJString(fargateProfileName))
  result = call_598135.call(path_598136, nil, nil, nil, nil)

var deleteFargateProfile* = Call_DeleteFargateProfile_598122(
    name: "deleteFargateProfile", meth: HttpMethod.HttpDelete,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DeleteFargateProfile_598123, base: "/",
    url: url_DeleteFargateProfile_598124, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodegroup_598137 = ref object of OpenApiRestCall_597390
proc url_DescribeNodegroup_598139(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeNodegroup_598138(path: JsonNode; query: JsonNode;
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
  var valid_598140 = path.getOrDefault("name")
  valid_598140 = validateParameter(valid_598140, JString, required = true,
                                 default = nil)
  if valid_598140 != nil:
    section.add "name", valid_598140
  var valid_598141 = path.getOrDefault("nodegroupName")
  valid_598141 = validateParameter(valid_598141, JString, required = true,
                                 default = nil)
  if valid_598141 != nil:
    section.add "nodegroupName", valid_598141
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
  var valid_598142 = header.getOrDefault("X-Amz-Signature")
  valid_598142 = validateParameter(valid_598142, JString, required = false,
                                 default = nil)
  if valid_598142 != nil:
    section.add "X-Amz-Signature", valid_598142
  var valid_598143 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598143 = validateParameter(valid_598143, JString, required = false,
                                 default = nil)
  if valid_598143 != nil:
    section.add "X-Amz-Content-Sha256", valid_598143
  var valid_598144 = header.getOrDefault("X-Amz-Date")
  valid_598144 = validateParameter(valid_598144, JString, required = false,
                                 default = nil)
  if valid_598144 != nil:
    section.add "X-Amz-Date", valid_598144
  var valid_598145 = header.getOrDefault("X-Amz-Credential")
  valid_598145 = validateParameter(valid_598145, JString, required = false,
                                 default = nil)
  if valid_598145 != nil:
    section.add "X-Amz-Credential", valid_598145
  var valid_598146 = header.getOrDefault("X-Amz-Security-Token")
  valid_598146 = validateParameter(valid_598146, JString, required = false,
                                 default = nil)
  if valid_598146 != nil:
    section.add "X-Amz-Security-Token", valid_598146
  var valid_598147 = header.getOrDefault("X-Amz-Algorithm")
  valid_598147 = validateParameter(valid_598147, JString, required = false,
                                 default = nil)
  if valid_598147 != nil:
    section.add "X-Amz-Algorithm", valid_598147
  var valid_598148 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598148 = validateParameter(valid_598148, JString, required = false,
                                 default = nil)
  if valid_598148 != nil:
    section.add "X-Amz-SignedHeaders", valid_598148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598149: Call_DescribeNodegroup_598137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptive information about an Amazon EKS node group.
  ## 
  let valid = call_598149.validator(path, query, header, formData, body)
  let scheme = call_598149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598149.url(scheme.get, call_598149.host, call_598149.base,
                         call_598149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598149, url, valid)

proc call*(call_598150: Call_DescribeNodegroup_598137; name: string;
          nodegroupName: string): Recallable =
  ## describeNodegroup
  ## Returns descriptive information about an Amazon EKS node group.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to describe.
  var path_598151 = newJObject()
  add(path_598151, "name", newJString(name))
  add(path_598151, "nodegroupName", newJString(nodegroupName))
  result = call_598150.call(path_598151, nil, nil, nil, nil)

var describeNodegroup* = Call_DescribeNodegroup_598137(name: "describeNodegroup",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DescribeNodegroup_598138, base: "/",
    url: url_DescribeNodegroup_598139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNodegroup_598152 = ref object of OpenApiRestCall_597390
proc url_DeleteNodegroup_598154(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNodegroup_598153(path: JsonNode; query: JsonNode;
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
  var valid_598155 = path.getOrDefault("name")
  valid_598155 = validateParameter(valid_598155, JString, required = true,
                                 default = nil)
  if valid_598155 != nil:
    section.add "name", valid_598155
  var valid_598156 = path.getOrDefault("nodegroupName")
  valid_598156 = validateParameter(valid_598156, JString, required = true,
                                 default = nil)
  if valid_598156 != nil:
    section.add "nodegroupName", valid_598156
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
  var valid_598157 = header.getOrDefault("X-Amz-Signature")
  valid_598157 = validateParameter(valid_598157, JString, required = false,
                                 default = nil)
  if valid_598157 != nil:
    section.add "X-Amz-Signature", valid_598157
  var valid_598158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598158 = validateParameter(valid_598158, JString, required = false,
                                 default = nil)
  if valid_598158 != nil:
    section.add "X-Amz-Content-Sha256", valid_598158
  var valid_598159 = header.getOrDefault("X-Amz-Date")
  valid_598159 = validateParameter(valid_598159, JString, required = false,
                                 default = nil)
  if valid_598159 != nil:
    section.add "X-Amz-Date", valid_598159
  var valid_598160 = header.getOrDefault("X-Amz-Credential")
  valid_598160 = validateParameter(valid_598160, JString, required = false,
                                 default = nil)
  if valid_598160 != nil:
    section.add "X-Amz-Credential", valid_598160
  var valid_598161 = header.getOrDefault("X-Amz-Security-Token")
  valid_598161 = validateParameter(valid_598161, JString, required = false,
                                 default = nil)
  if valid_598161 != nil:
    section.add "X-Amz-Security-Token", valid_598161
  var valid_598162 = header.getOrDefault("X-Amz-Algorithm")
  valid_598162 = validateParameter(valid_598162, JString, required = false,
                                 default = nil)
  if valid_598162 != nil:
    section.add "X-Amz-Algorithm", valid_598162
  var valid_598163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598163 = validateParameter(valid_598163, JString, required = false,
                                 default = nil)
  if valid_598163 != nil:
    section.add "X-Amz-SignedHeaders", valid_598163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598164: Call_DeleteNodegroup_598152; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon EKS node group for a cluster.
  ## 
  let valid = call_598164.validator(path, query, header, formData, body)
  let scheme = call_598164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598164.url(scheme.get, call_598164.host, call_598164.base,
                         call_598164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598164, url, valid)

proc call*(call_598165: Call_DeleteNodegroup_598152; name: string;
          nodegroupName: string): Recallable =
  ## deleteNodegroup
  ## Deletes an Amazon EKS node group for a cluster.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with your node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to delete.
  var path_598166 = newJObject()
  add(path_598166, "name", newJString(name))
  add(path_598166, "nodegroupName", newJString(nodegroupName))
  result = call_598165.call(path_598166, nil, nil, nil, nil)

var deleteNodegroup* = Call_DeleteNodegroup_598152(name: "deleteNodegroup",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DeleteNodegroup_598153, base: "/", url: url_DeleteNodegroup_598154,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUpdate_598167 = ref object of OpenApiRestCall_597390
proc url_DescribeUpdate_598169(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUpdate_598168(path: JsonNode; query: JsonNode;
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
  var valid_598170 = path.getOrDefault("updateId")
  valid_598170 = validateParameter(valid_598170, JString, required = true,
                                 default = nil)
  if valid_598170 != nil:
    section.add "updateId", valid_598170
  var valid_598171 = path.getOrDefault("name")
  valid_598171 = validateParameter(valid_598171, JString, required = true,
                                 default = nil)
  if valid_598171 != nil:
    section.add "name", valid_598171
  result.add "path", section
  ## parameters in `query` object:
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS node group associated with the update.
  section = newJObject()
  var valid_598172 = query.getOrDefault("nodegroupName")
  valid_598172 = validateParameter(valid_598172, JString, required = false,
                                 default = nil)
  if valid_598172 != nil:
    section.add "nodegroupName", valid_598172
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
  var valid_598173 = header.getOrDefault("X-Amz-Signature")
  valid_598173 = validateParameter(valid_598173, JString, required = false,
                                 default = nil)
  if valid_598173 != nil:
    section.add "X-Amz-Signature", valid_598173
  var valid_598174 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598174 = validateParameter(valid_598174, JString, required = false,
                                 default = nil)
  if valid_598174 != nil:
    section.add "X-Amz-Content-Sha256", valid_598174
  var valid_598175 = header.getOrDefault("X-Amz-Date")
  valid_598175 = validateParameter(valid_598175, JString, required = false,
                                 default = nil)
  if valid_598175 != nil:
    section.add "X-Amz-Date", valid_598175
  var valid_598176 = header.getOrDefault("X-Amz-Credential")
  valid_598176 = validateParameter(valid_598176, JString, required = false,
                                 default = nil)
  if valid_598176 != nil:
    section.add "X-Amz-Credential", valid_598176
  var valid_598177 = header.getOrDefault("X-Amz-Security-Token")
  valid_598177 = validateParameter(valid_598177, JString, required = false,
                                 default = nil)
  if valid_598177 != nil:
    section.add "X-Amz-Security-Token", valid_598177
  var valid_598178 = header.getOrDefault("X-Amz-Algorithm")
  valid_598178 = validateParameter(valid_598178, JString, required = false,
                                 default = nil)
  if valid_598178 != nil:
    section.add "X-Amz-Algorithm", valid_598178
  var valid_598179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598179 = validateParameter(valid_598179, JString, required = false,
                                 default = nil)
  if valid_598179 != nil:
    section.add "X-Amz-SignedHeaders", valid_598179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598180: Call_DescribeUpdate_598167; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ## 
  let valid = call_598180.validator(path, query, header, formData, body)
  let scheme = call_598180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598180.url(scheme.get, call_598180.host, call_598180.base,
                         call_598180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598180, url, valid)

proc call*(call_598181: Call_DescribeUpdate_598167; updateId: string; name: string;
          nodegroupName: string = ""): Recallable =
  ## describeUpdate
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ##   updateId: string (required)
  ##           : The ID of the update to describe.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the update.
  ##   nodegroupName: string
  ##                : The name of the Amazon EKS node group associated with the update.
  var path_598182 = newJObject()
  var query_598183 = newJObject()
  add(path_598182, "updateId", newJString(updateId))
  add(path_598182, "name", newJString(name))
  add(query_598183, "nodegroupName", newJString(nodegroupName))
  result = call_598181.call(path_598182, query_598183, nil, nil, nil)

var describeUpdate* = Call_DescribeUpdate_598167(name: "describeUpdate",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/updates/{updateId}",
    validator: validate_DescribeUpdate_598168, base: "/", url: url_DescribeUpdate_598169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_598198 = ref object of OpenApiRestCall_597390
proc url_TagResource_598200(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_598199(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598201 = path.getOrDefault("resourceArn")
  valid_598201 = validateParameter(valid_598201, JString, required = true,
                                 default = nil)
  if valid_598201 != nil:
    section.add "resourceArn", valid_598201
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
  var valid_598202 = header.getOrDefault("X-Amz-Signature")
  valid_598202 = validateParameter(valid_598202, JString, required = false,
                                 default = nil)
  if valid_598202 != nil:
    section.add "X-Amz-Signature", valid_598202
  var valid_598203 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598203 = validateParameter(valid_598203, JString, required = false,
                                 default = nil)
  if valid_598203 != nil:
    section.add "X-Amz-Content-Sha256", valid_598203
  var valid_598204 = header.getOrDefault("X-Amz-Date")
  valid_598204 = validateParameter(valid_598204, JString, required = false,
                                 default = nil)
  if valid_598204 != nil:
    section.add "X-Amz-Date", valid_598204
  var valid_598205 = header.getOrDefault("X-Amz-Credential")
  valid_598205 = validateParameter(valid_598205, JString, required = false,
                                 default = nil)
  if valid_598205 != nil:
    section.add "X-Amz-Credential", valid_598205
  var valid_598206 = header.getOrDefault("X-Amz-Security-Token")
  valid_598206 = validateParameter(valid_598206, JString, required = false,
                                 default = nil)
  if valid_598206 != nil:
    section.add "X-Amz-Security-Token", valid_598206
  var valid_598207 = header.getOrDefault("X-Amz-Algorithm")
  valid_598207 = validateParameter(valid_598207, JString, required = false,
                                 default = nil)
  if valid_598207 != nil:
    section.add "X-Amz-Algorithm", valid_598207
  var valid_598208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598208 = validateParameter(valid_598208, JString, required = false,
                                 default = nil)
  if valid_598208 != nil:
    section.add "X-Amz-SignedHeaders", valid_598208
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598210: Call_TagResource_598198; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ## 
  let valid = call_598210.validator(path, query, header, formData, body)
  let scheme = call_598210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598210.url(scheme.get, call_598210.host, call_598210.base,
                         call_598210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598210, url, valid)

proc call*(call_598211: Call_TagResource_598198; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to which to add tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  ##   body: JObject (required)
  var path_598212 = newJObject()
  var body_598213 = newJObject()
  add(path_598212, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_598213 = body
  result = call_598211.call(path_598212, nil, nil, nil, body_598213)

var tagResource* = Call_TagResource_598198(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "eks.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_598199,
                                        base: "/", url: url_TagResource_598200,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_598184 = ref object of OpenApiRestCall_597390
proc url_ListTagsForResource_598186(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_598185(path: JsonNode; query: JsonNode;
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
  var valid_598187 = path.getOrDefault("resourceArn")
  valid_598187 = validateParameter(valid_598187, JString, required = true,
                                 default = nil)
  if valid_598187 != nil:
    section.add "resourceArn", valid_598187
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
  var valid_598188 = header.getOrDefault("X-Amz-Signature")
  valid_598188 = validateParameter(valid_598188, JString, required = false,
                                 default = nil)
  if valid_598188 != nil:
    section.add "X-Amz-Signature", valid_598188
  var valid_598189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598189 = validateParameter(valid_598189, JString, required = false,
                                 default = nil)
  if valid_598189 != nil:
    section.add "X-Amz-Content-Sha256", valid_598189
  var valid_598190 = header.getOrDefault("X-Amz-Date")
  valid_598190 = validateParameter(valid_598190, JString, required = false,
                                 default = nil)
  if valid_598190 != nil:
    section.add "X-Amz-Date", valid_598190
  var valid_598191 = header.getOrDefault("X-Amz-Credential")
  valid_598191 = validateParameter(valid_598191, JString, required = false,
                                 default = nil)
  if valid_598191 != nil:
    section.add "X-Amz-Credential", valid_598191
  var valid_598192 = header.getOrDefault("X-Amz-Security-Token")
  valid_598192 = validateParameter(valid_598192, JString, required = false,
                                 default = nil)
  if valid_598192 != nil:
    section.add "X-Amz-Security-Token", valid_598192
  var valid_598193 = header.getOrDefault("X-Amz-Algorithm")
  valid_598193 = validateParameter(valid_598193, JString, required = false,
                                 default = nil)
  if valid_598193 != nil:
    section.add "X-Amz-Algorithm", valid_598193
  var valid_598194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598194 = validateParameter(valid_598194, JString, required = false,
                                 default = nil)
  if valid_598194 != nil:
    section.add "X-Amz-SignedHeaders", valid_598194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598195: Call_ListTagsForResource_598184; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon EKS resource.
  ## 
  let valid = call_598195.validator(path, query, header, formData, body)
  let scheme = call_598195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598195.url(scheme.get, call_598195.host, call_598195.base,
                         call_598195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598195, url, valid)

proc call*(call_598196: Call_ListTagsForResource_598184; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon EKS resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_598197 = newJObject()
  add(path_598197, "resourceArn", newJString(resourceArn))
  result = call_598196.call(path_598197, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_598184(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_598185, base: "/",
    url: url_ListTagsForResource_598186, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterVersion_598232 = ref object of OpenApiRestCall_597390
proc url_UpdateClusterVersion_598234(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterVersion_598233(path: JsonNode; query: JsonNode;
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
  var valid_598235 = path.getOrDefault("name")
  valid_598235 = validateParameter(valid_598235, JString, required = true,
                                 default = nil)
  if valid_598235 != nil:
    section.add "name", valid_598235
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
  var valid_598236 = header.getOrDefault("X-Amz-Signature")
  valid_598236 = validateParameter(valid_598236, JString, required = false,
                                 default = nil)
  if valid_598236 != nil:
    section.add "X-Amz-Signature", valid_598236
  var valid_598237 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598237 = validateParameter(valid_598237, JString, required = false,
                                 default = nil)
  if valid_598237 != nil:
    section.add "X-Amz-Content-Sha256", valid_598237
  var valid_598238 = header.getOrDefault("X-Amz-Date")
  valid_598238 = validateParameter(valid_598238, JString, required = false,
                                 default = nil)
  if valid_598238 != nil:
    section.add "X-Amz-Date", valid_598238
  var valid_598239 = header.getOrDefault("X-Amz-Credential")
  valid_598239 = validateParameter(valid_598239, JString, required = false,
                                 default = nil)
  if valid_598239 != nil:
    section.add "X-Amz-Credential", valid_598239
  var valid_598240 = header.getOrDefault("X-Amz-Security-Token")
  valid_598240 = validateParameter(valid_598240, JString, required = false,
                                 default = nil)
  if valid_598240 != nil:
    section.add "X-Amz-Security-Token", valid_598240
  var valid_598241 = header.getOrDefault("X-Amz-Algorithm")
  valid_598241 = validateParameter(valid_598241, JString, required = false,
                                 default = nil)
  if valid_598241 != nil:
    section.add "X-Amz-Algorithm", valid_598241
  var valid_598242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598242 = validateParameter(valid_598242, JString, required = false,
                                 default = nil)
  if valid_598242 != nil:
    section.add "X-Amz-SignedHeaders", valid_598242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598244: Call_UpdateClusterVersion_598232; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ## 
  let valid = call_598244.validator(path, query, header, formData, body)
  let scheme = call_598244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598244.url(scheme.get, call_598244.host, call_598244.base,
                         call_598244.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598244, url, valid)

proc call*(call_598245: Call_UpdateClusterVersion_598232; name: string;
          body: JsonNode): Recallable =
  ## updateClusterVersion
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_598246 = newJObject()
  var body_598247 = newJObject()
  add(path_598246, "name", newJString(name))
  if body != nil:
    body_598247 = body
  result = call_598245.call(path_598246, nil, nil, nil, body_598247)

var updateClusterVersion* = Call_UpdateClusterVersion_598232(
    name: "updateClusterVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/updates",
    validator: validate_UpdateClusterVersion_598233, base: "/",
    url: url_UpdateClusterVersion_598234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUpdates_598214 = ref object of OpenApiRestCall_597390
proc url_ListUpdates_598216(protocol: Scheme; host: string; base: string;
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

proc validate_ListUpdates_598215(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598217 = path.getOrDefault("name")
  valid_598217 = validateParameter(valid_598217, JString, required = true,
                                 default = nil)
  if valid_598217 != nil:
    section.add "name", valid_598217
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListUpdates</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS managed node group to list updates for.
  ##   maxResults: JInt
  ##             : The maximum number of update results returned by <code>ListUpdates</code> in paginated output. When you use this parameter, <code>ListUpdates</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListUpdates</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListUpdates</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_598218 = query.getOrDefault("nextToken")
  valid_598218 = validateParameter(valid_598218, JString, required = false,
                                 default = nil)
  if valid_598218 != nil:
    section.add "nextToken", valid_598218
  var valid_598219 = query.getOrDefault("nodegroupName")
  valid_598219 = validateParameter(valid_598219, JString, required = false,
                                 default = nil)
  if valid_598219 != nil:
    section.add "nodegroupName", valid_598219
  var valid_598220 = query.getOrDefault("maxResults")
  valid_598220 = validateParameter(valid_598220, JInt, required = false, default = nil)
  if valid_598220 != nil:
    section.add "maxResults", valid_598220
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
  var valid_598221 = header.getOrDefault("X-Amz-Signature")
  valid_598221 = validateParameter(valid_598221, JString, required = false,
                                 default = nil)
  if valid_598221 != nil:
    section.add "X-Amz-Signature", valid_598221
  var valid_598222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598222 = validateParameter(valid_598222, JString, required = false,
                                 default = nil)
  if valid_598222 != nil:
    section.add "X-Amz-Content-Sha256", valid_598222
  var valid_598223 = header.getOrDefault("X-Amz-Date")
  valid_598223 = validateParameter(valid_598223, JString, required = false,
                                 default = nil)
  if valid_598223 != nil:
    section.add "X-Amz-Date", valid_598223
  var valid_598224 = header.getOrDefault("X-Amz-Credential")
  valid_598224 = validateParameter(valid_598224, JString, required = false,
                                 default = nil)
  if valid_598224 != nil:
    section.add "X-Amz-Credential", valid_598224
  var valid_598225 = header.getOrDefault("X-Amz-Security-Token")
  valid_598225 = validateParameter(valid_598225, JString, required = false,
                                 default = nil)
  if valid_598225 != nil:
    section.add "X-Amz-Security-Token", valid_598225
  var valid_598226 = header.getOrDefault("X-Amz-Algorithm")
  valid_598226 = validateParameter(valid_598226, JString, required = false,
                                 default = nil)
  if valid_598226 != nil:
    section.add "X-Amz-Algorithm", valid_598226
  var valid_598227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598227 = validateParameter(valid_598227, JString, required = false,
                                 default = nil)
  if valid_598227 != nil:
    section.add "X-Amz-SignedHeaders", valid_598227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598228: Call_ListUpdates_598214; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
  ## 
  let valid = call_598228.validator(path, query, header, formData, body)
  let scheme = call_598228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598228.url(scheme.get, call_598228.host, call_598228.base,
                         call_598228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598228, url, valid)

proc call*(call_598229: Call_ListUpdates_598214; name: string;
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
  var path_598230 = newJObject()
  var query_598231 = newJObject()
  add(query_598231, "nextToken", newJString(nextToken))
  add(path_598230, "name", newJString(name))
  add(query_598231, "nodegroupName", newJString(nodegroupName))
  add(query_598231, "maxResults", newJInt(maxResults))
  result = call_598229.call(path_598230, query_598231, nil, nil, nil)

var listUpdates* = Call_ListUpdates_598214(name: "listUpdates",
                                        meth: HttpMethod.HttpGet,
                                        host: "eks.amazonaws.com",
                                        route: "/clusters/{name}/updates",
                                        validator: validate_ListUpdates_598215,
                                        base: "/", url: url_ListUpdates_598216,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_598248 = ref object of OpenApiRestCall_597390
proc url_UntagResource_598250(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_598249(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598251 = path.getOrDefault("resourceArn")
  valid_598251 = validateParameter(valid_598251, JString, required = true,
                                 default = nil)
  if valid_598251 != nil:
    section.add "resourceArn", valid_598251
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_598252 = query.getOrDefault("tagKeys")
  valid_598252 = validateParameter(valid_598252, JArray, required = true, default = nil)
  if valid_598252 != nil:
    section.add "tagKeys", valid_598252
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
  var valid_598253 = header.getOrDefault("X-Amz-Signature")
  valid_598253 = validateParameter(valid_598253, JString, required = false,
                                 default = nil)
  if valid_598253 != nil:
    section.add "X-Amz-Signature", valid_598253
  var valid_598254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598254 = validateParameter(valid_598254, JString, required = false,
                                 default = nil)
  if valid_598254 != nil:
    section.add "X-Amz-Content-Sha256", valid_598254
  var valid_598255 = header.getOrDefault("X-Amz-Date")
  valid_598255 = validateParameter(valid_598255, JString, required = false,
                                 default = nil)
  if valid_598255 != nil:
    section.add "X-Amz-Date", valid_598255
  var valid_598256 = header.getOrDefault("X-Amz-Credential")
  valid_598256 = validateParameter(valid_598256, JString, required = false,
                                 default = nil)
  if valid_598256 != nil:
    section.add "X-Amz-Credential", valid_598256
  var valid_598257 = header.getOrDefault("X-Amz-Security-Token")
  valid_598257 = validateParameter(valid_598257, JString, required = false,
                                 default = nil)
  if valid_598257 != nil:
    section.add "X-Amz-Security-Token", valid_598257
  var valid_598258 = header.getOrDefault("X-Amz-Algorithm")
  valid_598258 = validateParameter(valid_598258, JString, required = false,
                                 default = nil)
  if valid_598258 != nil:
    section.add "X-Amz-Algorithm", valid_598258
  var valid_598259 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598259 = validateParameter(valid_598259, JString, required = false,
                                 default = nil)
  if valid_598259 != nil:
    section.add "X-Amz-SignedHeaders", valid_598259
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598260: Call_UntagResource_598248; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_598260.validator(path, query, header, formData, body)
  let scheme = call_598260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598260.url(scheme.get, call_598260.host, call_598260.base,
                         call_598260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598260, url, valid)

proc call*(call_598261: Call_UntagResource_598248; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource from which to delete tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  var path_598262 = newJObject()
  var query_598263 = newJObject()
  add(path_598262, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_598263.add "tagKeys", tagKeys
  result = call_598261.call(path_598262, query_598263, nil, nil, nil)

var untagResource* = Call_UntagResource_598248(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_598249,
    base: "/", url: url_UntagResource_598250, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfig_598264 = ref object of OpenApiRestCall_597390
proc url_UpdateClusterConfig_598266(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterConfig_598265(path: JsonNode; query: JsonNode;
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
  var valid_598267 = path.getOrDefault("name")
  valid_598267 = validateParameter(valid_598267, JString, required = true,
                                 default = nil)
  if valid_598267 != nil:
    section.add "name", valid_598267
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
  var valid_598268 = header.getOrDefault("X-Amz-Signature")
  valid_598268 = validateParameter(valid_598268, JString, required = false,
                                 default = nil)
  if valid_598268 != nil:
    section.add "X-Amz-Signature", valid_598268
  var valid_598269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598269 = validateParameter(valid_598269, JString, required = false,
                                 default = nil)
  if valid_598269 != nil:
    section.add "X-Amz-Content-Sha256", valid_598269
  var valid_598270 = header.getOrDefault("X-Amz-Date")
  valid_598270 = validateParameter(valid_598270, JString, required = false,
                                 default = nil)
  if valid_598270 != nil:
    section.add "X-Amz-Date", valid_598270
  var valid_598271 = header.getOrDefault("X-Amz-Credential")
  valid_598271 = validateParameter(valid_598271, JString, required = false,
                                 default = nil)
  if valid_598271 != nil:
    section.add "X-Amz-Credential", valid_598271
  var valid_598272 = header.getOrDefault("X-Amz-Security-Token")
  valid_598272 = validateParameter(valid_598272, JString, required = false,
                                 default = nil)
  if valid_598272 != nil:
    section.add "X-Amz-Security-Token", valid_598272
  var valid_598273 = header.getOrDefault("X-Amz-Algorithm")
  valid_598273 = validateParameter(valid_598273, JString, required = false,
                                 default = nil)
  if valid_598273 != nil:
    section.add "X-Amz-Algorithm", valid_598273
  var valid_598274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598274 = validateParameter(valid_598274, JString, required = false,
                                 default = nil)
  if valid_598274 != nil:
    section.add "X-Amz-SignedHeaders", valid_598274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598276: Call_UpdateClusterConfig_598264; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ## 
  let valid = call_598276.validator(path, query, header, formData, body)
  let scheme = call_598276.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598276.url(scheme.get, call_598276.host, call_598276.base,
                         call_598276.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598276, url, valid)

proc call*(call_598277: Call_UpdateClusterConfig_598264; name: string; body: JsonNode): Recallable =
  ## updateClusterConfig
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_598278 = newJObject()
  var body_598279 = newJObject()
  add(path_598278, "name", newJString(name))
  if body != nil:
    body_598279 = body
  result = call_598277.call(path_598278, nil, nil, nil, body_598279)

var updateClusterConfig* = Call_UpdateClusterConfig_598264(
    name: "updateClusterConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/update-config",
    validator: validate_UpdateClusterConfig_598265, base: "/",
    url: url_UpdateClusterConfig_598266, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupConfig_598280 = ref object of OpenApiRestCall_597390
proc url_UpdateNodegroupConfig_598282(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNodegroupConfig_598281(path: JsonNode; query: JsonNode;
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
  var valid_598283 = path.getOrDefault("name")
  valid_598283 = validateParameter(valid_598283, JString, required = true,
                                 default = nil)
  if valid_598283 != nil:
    section.add "name", valid_598283
  var valid_598284 = path.getOrDefault("nodegroupName")
  valid_598284 = validateParameter(valid_598284, JString, required = true,
                                 default = nil)
  if valid_598284 != nil:
    section.add "nodegroupName", valid_598284
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
  var valid_598285 = header.getOrDefault("X-Amz-Signature")
  valid_598285 = validateParameter(valid_598285, JString, required = false,
                                 default = nil)
  if valid_598285 != nil:
    section.add "X-Amz-Signature", valid_598285
  var valid_598286 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598286 = validateParameter(valid_598286, JString, required = false,
                                 default = nil)
  if valid_598286 != nil:
    section.add "X-Amz-Content-Sha256", valid_598286
  var valid_598287 = header.getOrDefault("X-Amz-Date")
  valid_598287 = validateParameter(valid_598287, JString, required = false,
                                 default = nil)
  if valid_598287 != nil:
    section.add "X-Amz-Date", valid_598287
  var valid_598288 = header.getOrDefault("X-Amz-Credential")
  valid_598288 = validateParameter(valid_598288, JString, required = false,
                                 default = nil)
  if valid_598288 != nil:
    section.add "X-Amz-Credential", valid_598288
  var valid_598289 = header.getOrDefault("X-Amz-Security-Token")
  valid_598289 = validateParameter(valid_598289, JString, required = false,
                                 default = nil)
  if valid_598289 != nil:
    section.add "X-Amz-Security-Token", valid_598289
  var valid_598290 = header.getOrDefault("X-Amz-Algorithm")
  valid_598290 = validateParameter(valid_598290, JString, required = false,
                                 default = nil)
  if valid_598290 != nil:
    section.add "X-Amz-Algorithm", valid_598290
  var valid_598291 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598291 = validateParameter(valid_598291, JString, required = false,
                                 default = nil)
  if valid_598291 != nil:
    section.add "X-Amz-SignedHeaders", valid_598291
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598293: Call_UpdateNodegroupConfig_598280; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ## 
  let valid = call_598293.validator(path, query, header, formData, body)
  let scheme = call_598293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598293.url(scheme.get, call_598293.host, call_598293.base,
                         call_598293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598293, url, valid)

proc call*(call_598294: Call_UpdateNodegroupConfig_598280; name: string;
          body: JsonNode; nodegroupName: string): Recallable =
  ## updateNodegroupConfig
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that the managed node group resides in.
  ##   body: JObject (required)
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  var path_598295 = newJObject()
  var body_598296 = newJObject()
  add(path_598295, "name", newJString(name))
  if body != nil:
    body_598296 = body
  add(path_598295, "nodegroupName", newJString(nodegroupName))
  result = call_598294.call(path_598295, nil, nil, nil, body_598296)

var updateNodegroupConfig* = Call_UpdateNodegroupConfig_598280(
    name: "updateNodegroupConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-config",
    validator: validate_UpdateNodegroupConfig_598281, base: "/",
    url: url_UpdateNodegroupConfig_598282, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupVersion_598297 = ref object of OpenApiRestCall_597390
proc url_UpdateNodegroupVersion_598299(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNodegroupVersion_598298(path: JsonNode; query: JsonNode;
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
  var valid_598300 = path.getOrDefault("name")
  valid_598300 = validateParameter(valid_598300, JString, required = true,
                                 default = nil)
  if valid_598300 != nil:
    section.add "name", valid_598300
  var valid_598301 = path.getOrDefault("nodegroupName")
  valid_598301 = validateParameter(valid_598301, JString, required = true,
                                 default = nil)
  if valid_598301 != nil:
    section.add "nodegroupName", valid_598301
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
  var valid_598302 = header.getOrDefault("X-Amz-Signature")
  valid_598302 = validateParameter(valid_598302, JString, required = false,
                                 default = nil)
  if valid_598302 != nil:
    section.add "X-Amz-Signature", valid_598302
  var valid_598303 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598303 = validateParameter(valid_598303, JString, required = false,
                                 default = nil)
  if valid_598303 != nil:
    section.add "X-Amz-Content-Sha256", valid_598303
  var valid_598304 = header.getOrDefault("X-Amz-Date")
  valid_598304 = validateParameter(valid_598304, JString, required = false,
                                 default = nil)
  if valid_598304 != nil:
    section.add "X-Amz-Date", valid_598304
  var valid_598305 = header.getOrDefault("X-Amz-Credential")
  valid_598305 = validateParameter(valid_598305, JString, required = false,
                                 default = nil)
  if valid_598305 != nil:
    section.add "X-Amz-Credential", valid_598305
  var valid_598306 = header.getOrDefault("X-Amz-Security-Token")
  valid_598306 = validateParameter(valid_598306, JString, required = false,
                                 default = nil)
  if valid_598306 != nil:
    section.add "X-Amz-Security-Token", valid_598306
  var valid_598307 = header.getOrDefault("X-Amz-Algorithm")
  valid_598307 = validateParameter(valid_598307, JString, required = false,
                                 default = nil)
  if valid_598307 != nil:
    section.add "X-Amz-Algorithm", valid_598307
  var valid_598308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598308 = validateParameter(valid_598308, JString, required = false,
                                 default = nil)
  if valid_598308 != nil:
    section.add "X-Amz-SignedHeaders", valid_598308
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_598310: Call_UpdateNodegroupVersion_598297; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ## 
  let valid = call_598310.validator(path, query, header, formData, body)
  let scheme = call_598310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598310.url(scheme.get, call_598310.host, call_598310.base,
                         call_598310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598310, url, valid)

proc call*(call_598311: Call_UpdateNodegroupVersion_598297; name: string;
          body: JsonNode; nodegroupName: string): Recallable =
  ## updateNodegroupVersion
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with the managed node group to update.
  ##   body: JObject (required)
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  var path_598312 = newJObject()
  var body_598313 = newJObject()
  add(path_598312, "name", newJString(name))
  if body != nil:
    body_598313 = body
  add(path_598312, "nodegroupName", newJString(nodegroupName))
  result = call_598311.call(path_598312, nil, nil, nil, body_598313)

var updateNodegroupVersion* = Call_UpdateNodegroupVersion_598297(
    name: "updateNodegroupVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-version",
    validator: validate_UpdateNodegroupVersion_598298, base: "/",
    url: url_UpdateNodegroupVersion_598299, schemes: {Scheme.Https, Scheme.Http})
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
