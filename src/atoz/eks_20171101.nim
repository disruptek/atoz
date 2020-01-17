
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

  OpenApiRestCall_605590 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605590](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605590): Option[Scheme] {.used.} =
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
  Call_CreateCluster_606185 = ref object of OpenApiRestCall_605590
proc url_CreateCluster_606187(protocol: Scheme; host: string; base: string;
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

proc validate_CreateCluster_606186(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606188 = header.getOrDefault("X-Amz-Signature")
  valid_606188 = validateParameter(valid_606188, JString, required = false,
                                 default = nil)
  if valid_606188 != nil:
    section.add "X-Amz-Signature", valid_606188
  var valid_606189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Content-Sha256", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Date")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Date", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Credential")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Credential", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Security-Token")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Security-Token", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Algorithm")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Algorithm", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-SignedHeaders", valid_606194
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606196: Call_CreateCluster_606185; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  let valid = call_606196.validator(path, query, header, formData, body)
  let scheme = call_606196.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606196.url(scheme.get, call_606196.host, call_606196.base,
                         call_606196.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606196, url, valid)

proc call*(call_606197: Call_CreateCluster_606185; body: JsonNode): Recallable =
  ## createCluster
  ## <p>Creates an Amazon EKS control plane. </p> <p>The Amazon EKS control plane consists of control plane instances that run the Kubernetes software, such as <code>etcd</code> and the API server. The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS API server endpoint. Each Amazon EKS cluster control plane is single-tenant and unique and runs on its own set of Amazon EC2 instances.</p> <p>The cluster control plane is provisioned across multiple Availability Zones and fronted by an Elastic Load Balancing Network Load Balancer. Amazon EKS also provisions elastic network interfaces in your VPC subnets to provide connectivity from the control plane instances to the worker nodes (for example, to support <code>kubectl exec</code>, <code>logs</code>, and <code>proxy</code> data flows).</p> <p>Amazon EKS worker nodes run in your AWS account and connect to your cluster's control plane via the Kubernetes API server endpoint and a certificate file that is created for your cluster.</p> <p>You can use the <code>endpointPublicAccess</code> and <code>endpointPrivateAccess</code> parameters to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <p>You can use the <code>logging</code> parameter to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>Cluster creation typically takes between 10 and 15 minutes. After you create an Amazon EKS cluster, you must configure your Kubernetes tooling to communicate with the API server and launch worker nodes into your cluster. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managing-auth.html">Managing Cluster Authentication</a> and <a href="https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html">Launching Amazon EKS Worker Nodes</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   body: JObject (required)
  var body_606198 = newJObject()
  if body != nil:
    body_606198 = body
  result = call_606197.call(nil, nil, nil, nil, body_606198)

var createCluster* = Call_CreateCluster_606185(name: "createCluster",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_CreateCluster_606186, base: "/", url: url_CreateCluster_606187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListClusters_605928 = ref object of OpenApiRestCall_605590
proc url_ListClusters_605930(protocol: Scheme; host: string; base: string;
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

proc validate_ListClusters_605929(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606042 = query.getOrDefault("nextToken")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "nextToken", valid_606042
  var valid_606043 = query.getOrDefault("maxResults")
  valid_606043 = validateParameter(valid_606043, JInt, required = false, default = nil)
  if valid_606043 != nil:
    section.add "maxResults", valid_606043
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
  var valid_606044 = header.getOrDefault("X-Amz-Signature")
  valid_606044 = validateParameter(valid_606044, JString, required = false,
                                 default = nil)
  if valid_606044 != nil:
    section.add "X-Amz-Signature", valid_606044
  var valid_606045 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Content-Sha256", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Date")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Date", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Credential")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Credential", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Security-Token")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Security-Token", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Algorithm")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Algorithm", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-SignedHeaders", valid_606050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606073: Call_ListClusters_605928; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ## 
  let valid = call_606073.validator(path, query, header, formData, body)
  let scheme = call_606073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606073.url(scheme.get, call_606073.host, call_606073.base,
                         call_606073.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606073, url, valid)

proc call*(call_606144: Call_ListClusters_605928; nextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listClusters
  ## Lists the Amazon EKS clusters in your AWS account in the specified Region.
  ##   nextToken: string
  ##            : <p>The <code>nextToken</code> value returned from a previous paginated <code>ListClusters</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.</p> <note> <p>This token should be treated as an opaque identifier that is used only to retrieve the next items in a list and not for other programmatic purposes.</p> </note>
  ##   maxResults: int
  ##             : The maximum number of cluster results returned by <code>ListClusters</code> in paginated output. When you use this parameter, <code>ListClusters</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListClusters</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListClusters</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var query_606145 = newJObject()
  add(query_606145, "nextToken", newJString(nextToken))
  add(query_606145, "maxResults", newJInt(maxResults))
  result = call_606144.call(nil, query_606145, nil, nil, nil)

var listClusters* = Call_ListClusters_605928(name: "listClusters",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters",
    validator: validate_ListClusters_605929, base: "/", url: url_ListClusters_605930,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFargateProfile_606230 = ref object of OpenApiRestCall_605590
proc url_CreateFargateProfile_606232(protocol: Scheme; host: string; base: string;
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

proc validate_CreateFargateProfile_606231(path: JsonNode; query: JsonNode;
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
  var valid_606233 = path.getOrDefault("name")
  valid_606233 = validateParameter(valid_606233, JString, required = true,
                                 default = nil)
  if valid_606233 != nil:
    section.add "name", valid_606233
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
  var valid_606234 = header.getOrDefault("X-Amz-Signature")
  valid_606234 = validateParameter(valid_606234, JString, required = false,
                                 default = nil)
  if valid_606234 != nil:
    section.add "X-Amz-Signature", valid_606234
  var valid_606235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "X-Amz-Content-Sha256", valid_606235
  var valid_606236 = header.getOrDefault("X-Amz-Date")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "X-Amz-Date", valid_606236
  var valid_606237 = header.getOrDefault("X-Amz-Credential")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "X-Amz-Credential", valid_606237
  var valid_606238 = header.getOrDefault("X-Amz-Security-Token")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "X-Amz-Security-Token", valid_606238
  var valid_606239 = header.getOrDefault("X-Amz-Algorithm")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Algorithm", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-SignedHeaders", valid_606240
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606242: Call_CreateFargateProfile_606230; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ## 
  let valid = call_606242.validator(path, query, header, formData, body)
  let scheme = call_606242.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606242.url(scheme.get, call_606242.host, call_606242.base,
                         call_606242.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606242, url, valid)

proc call*(call_606243: Call_CreateFargateProfile_606230; name: string;
          body: JsonNode): Recallable =
  ## createFargateProfile
  ## <p>Creates an AWS Fargate profile for your Amazon EKS cluster. You must have at least one Fargate profile in a cluster to be able to run pods on Fargate.</p> <p>The Fargate profile allows an administrator to declare which pods run on Fargate and specify which pods run on which Fargate profile. This declaration is done through the profile’s selectors. Each profile can have up to five selectors that contain a namespace and labels. A namespace is required for every selector. The label field consists of multiple optional key-value pairs. Pods that match the selectors are scheduled on Fargate. If a to-be-scheduled pod matches any of the selectors in the Fargate profile, then that pod is run on Fargate.</p> <p>When you create a Fargate profile, you must specify a pod execution role to use with the pods that are scheduled with the profile. This role is added to the cluster's Kubernetes <a href="https://kubernetes.io/docs/admin/authorization/rbac/">Role Based Access Control</a> (RBAC) for authorization so that the <code>kubelet</code> that is running on the Fargate infrastructure can register with your Amazon EKS cluster so that it can appear in your cluster as a node. The pod execution role also provides IAM permissions to the Fargate infrastructure to allow read access to Amazon ECR image repositories. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/pod-execution-role.html">Pod Execution Role</a> in the <i>Amazon EKS User Guide</i>.</p> <p>Fargate profiles are immutable. However, you can create a new updated profile to replace an existing profile and then delete the original after the updated profile has finished creating.</p> <p>If any Fargate profiles in a cluster are in the <code>DELETING</code> status, you must wait for that Fargate profile to finish deleting before you can create any other profiles in that cluster.</p> <p>For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/fargate-profile.html">AWS Fargate Profile</a> in the <i>Amazon EKS User Guide</i>.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to apply the Fargate profile to.
  ##   body: JObject (required)
  var path_606244 = newJObject()
  var body_606245 = newJObject()
  add(path_606244, "name", newJString(name))
  if body != nil:
    body_606245 = body
  result = call_606243.call(path_606244, nil, nil, nil, body_606245)

var createFargateProfile* = Call_CreateFargateProfile_606230(
    name: "createFargateProfile", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_CreateFargateProfile_606231, base: "/",
    url: url_CreateFargateProfile_606232, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFargateProfiles_606199 = ref object of OpenApiRestCall_605590
proc url_ListFargateProfiles_606201(protocol: Scheme; host: string; base: string;
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

proc validate_ListFargateProfiles_606200(path: JsonNode; query: JsonNode;
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
  var valid_606216 = path.getOrDefault("name")
  valid_606216 = validateParameter(valid_606216, JString, required = true,
                                 default = nil)
  if valid_606216 != nil:
    section.add "name", valid_606216
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListFargateProfiles</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   maxResults: JInt
  ##             : The maximum number of Fargate profile results returned by <code>ListFargateProfiles</code> in paginated output. When you use this parameter, <code>ListFargateProfiles</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListFargateProfiles</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListFargateProfiles</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_606217 = query.getOrDefault("nextToken")
  valid_606217 = validateParameter(valid_606217, JString, required = false,
                                 default = nil)
  if valid_606217 != nil:
    section.add "nextToken", valid_606217
  var valid_606218 = query.getOrDefault("maxResults")
  valid_606218 = validateParameter(valid_606218, JInt, required = false, default = nil)
  if valid_606218 != nil:
    section.add "maxResults", valid_606218
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
  var valid_606219 = header.getOrDefault("X-Amz-Signature")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "X-Amz-Signature", valid_606219
  var valid_606220 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606220 = validateParameter(valid_606220, JString, required = false,
                                 default = nil)
  if valid_606220 != nil:
    section.add "X-Amz-Content-Sha256", valid_606220
  var valid_606221 = header.getOrDefault("X-Amz-Date")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "X-Amz-Date", valid_606221
  var valid_606222 = header.getOrDefault("X-Amz-Credential")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Credential", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Security-Token")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Security-Token", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Algorithm")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Algorithm", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-SignedHeaders", valid_606225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606226: Call_ListFargateProfiles_606199; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ## 
  let valid = call_606226.validator(path, query, header, formData, body)
  let scheme = call_606226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606226.url(scheme.get, call_606226.host, call_606226.base,
                         call_606226.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606226, url, valid)

proc call*(call_606227: Call_ListFargateProfiles_606199; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listFargateProfiles
  ## Lists the AWS Fargate profiles associated with the specified cluster in your AWS account in the specified Region.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListFargateProfiles</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that you would like to listFargate profiles in.
  ##   maxResults: int
  ##             : The maximum number of Fargate profile results returned by <code>ListFargateProfiles</code> in paginated output. When you use this parameter, <code>ListFargateProfiles</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListFargateProfiles</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListFargateProfiles</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var path_606228 = newJObject()
  var query_606229 = newJObject()
  add(query_606229, "nextToken", newJString(nextToken))
  add(path_606228, "name", newJString(name))
  add(query_606229, "maxResults", newJInt(maxResults))
  result = call_606227.call(path_606228, query_606229, nil, nil, nil)

var listFargateProfiles* = Call_ListFargateProfiles_606199(
    name: "listFargateProfiles", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/clusters/{name}/fargate-profiles",
    validator: validate_ListFargateProfiles_606200, base: "/",
    url: url_ListFargateProfiles_606201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateNodegroup_606263 = ref object of OpenApiRestCall_605590
proc url_CreateNodegroup_606265(protocol: Scheme; host: string; base: string;
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

proc validate_CreateNodegroup_606264(path: JsonNode; query: JsonNode;
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
  var valid_606266 = path.getOrDefault("name")
  valid_606266 = validateParameter(valid_606266, JString, required = true,
                                 default = nil)
  if valid_606266 != nil:
    section.add "name", valid_606266
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
  var valid_606267 = header.getOrDefault("X-Amz-Signature")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "X-Amz-Signature", valid_606267
  var valid_606268 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Content-Sha256", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Date")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Date", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Credential")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Credential", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Security-Token")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Security-Token", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Algorithm")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Algorithm", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-SignedHeaders", valid_606273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606275: Call_CreateNodegroup_606263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ## 
  let valid = call_606275.validator(path, query, header, formData, body)
  let scheme = call_606275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606275.url(scheme.get, call_606275.host, call_606275.base,
                         call_606275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606275, url, valid)

proc call*(call_606276: Call_CreateNodegroup_606263; name: string; body: JsonNode): Recallable =
  ## createNodegroup
  ## <p>Creates a managed worker node group for an Amazon EKS cluster. You can only create a node group for your cluster that is equal to the current Kubernetes version for the cluster. All node groups are created with the latest AMI release version for the respective minor Kubernetes version of the cluster.</p> <p>An Amazon EKS managed node group is an Amazon EC2 Auto Scaling group and associated Amazon EC2 instances that are managed by AWS for an Amazon EKS cluster. Each node group uses a version of the Amazon EKS-optimized Amazon Linux 2 AMI. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html">Managed Node Groups</a> in the <i>Amazon EKS User Guide</i>. </p>
  ##   name: string (required)
  ##       : The name of the cluster to create the node group in.
  ##   body: JObject (required)
  var path_606277 = newJObject()
  var body_606278 = newJObject()
  add(path_606277, "name", newJString(name))
  if body != nil:
    body_606278 = body
  result = call_606276.call(path_606277, nil, nil, nil, body_606278)

var createNodegroup* = Call_CreateNodegroup_606263(name: "createNodegroup",
    meth: HttpMethod.HttpPost, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_CreateNodegroup_606264,
    base: "/", url: url_CreateNodegroup_606265, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListNodegroups_606246 = ref object of OpenApiRestCall_605590
proc url_ListNodegroups_606248(protocol: Scheme; host: string; base: string;
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

proc validate_ListNodegroups_606247(path: JsonNode; query: JsonNode;
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
  var valid_606249 = path.getOrDefault("name")
  valid_606249 = validateParameter(valid_606249, JString, required = true,
                                 default = nil)
  if valid_606249 != nil:
    section.add "name", valid_606249
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   maxResults: JInt
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_606250 = query.getOrDefault("nextToken")
  valid_606250 = validateParameter(valid_606250, JString, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "nextToken", valid_606250
  var valid_606251 = query.getOrDefault("maxResults")
  valid_606251 = validateParameter(valid_606251, JInt, required = false, default = nil)
  if valid_606251 != nil:
    section.add "maxResults", valid_606251
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
  var valid_606252 = header.getOrDefault("X-Amz-Signature")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Signature", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Content-Sha256", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Date")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Date", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Credential")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Credential", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Security-Token")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Security-Token", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Algorithm")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Algorithm", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-SignedHeaders", valid_606258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606259: Call_ListNodegroups_606246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ## 
  let valid = call_606259.validator(path, query, header, formData, body)
  let scheme = call_606259.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606259.url(scheme.get, call_606259.host, call_606259.base,
                         call_606259.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606259, url, valid)

proc call*(call_606260: Call_ListNodegroups_606246; name: string;
          nextToken: string = ""; maxResults: int = 0): Recallable =
  ## listNodegroups
  ## Lists the Amazon EKS node groups associated with the specified cluster in your AWS account in the specified Region.
  ##   nextToken: string
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListNodegroups</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that you would like to list node groups in.
  ##   maxResults: int
  ##             : The maximum number of node group results returned by <code>ListNodegroups</code> in paginated output. When you use this parameter, <code>ListNodegroups</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListNodegroups</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListNodegroups</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  var path_606261 = newJObject()
  var query_606262 = newJObject()
  add(query_606262, "nextToken", newJString(nextToken))
  add(path_606261, "name", newJString(name))
  add(query_606262, "maxResults", newJInt(maxResults))
  result = call_606260.call(path_606261, query_606262, nil, nil, nil)

var listNodegroups* = Call_ListNodegroups_606246(name: "listNodegroups",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups", validator: validate_ListNodegroups_606247,
    base: "/", url: url_ListNodegroups_606248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeCluster_606279 = ref object of OpenApiRestCall_605590
proc url_DescribeCluster_606281(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeCluster_606280(path: JsonNode; query: JsonNode;
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
  var valid_606282 = path.getOrDefault("name")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "name", valid_606282
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
  var valid_606283 = header.getOrDefault("X-Amz-Signature")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Signature", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Content-Sha256", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Date")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Date", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Credential")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Credential", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Security-Token")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Security-Token", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Algorithm")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Algorithm", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-SignedHeaders", valid_606289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606290: Call_DescribeCluster_606279; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ## 
  let valid = call_606290.validator(path, query, header, formData, body)
  let scheme = call_606290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606290.url(scheme.get, call_606290.host, call_606290.base,
                         call_606290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606290, url, valid)

proc call*(call_606291: Call_DescribeCluster_606279; name: string): Recallable =
  ## describeCluster
  ## <p>Returns descriptive information about an Amazon EKS cluster.</p> <p>The API server endpoint and certificate authority data returned by this operation are required for <code>kubelet</code> and <code>kubectl</code> to communicate with your Kubernetes API server. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html">Create a kubeconfig for Amazon EKS</a>.</p> <note> <p>The API server endpoint and certificate authority data aren't available until the cluster reaches the <code>ACTIVE</code> state.</p> </note>
  ##   name: string (required)
  ##       : The name of the cluster to describe.
  var path_606292 = newJObject()
  add(path_606292, "name", newJString(name))
  result = call_606291.call(path_606292, nil, nil, nil, nil)

var describeCluster* = Call_DescribeCluster_606279(name: "describeCluster",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com", route: "/clusters/{name}",
    validator: validate_DescribeCluster_606280, base: "/", url: url_DescribeCluster_606281,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteCluster_606293 = ref object of OpenApiRestCall_605590
proc url_DeleteCluster_606295(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteCluster_606294(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606296 = path.getOrDefault("name")
  valid_606296 = validateParameter(valid_606296, JString, required = true,
                                 default = nil)
  if valid_606296 != nil:
    section.add "name", valid_606296
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
  var valid_606297 = header.getOrDefault("X-Amz-Signature")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Signature", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Content-Sha256", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Date")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Date", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Credential")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Credential", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Security-Token")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Security-Token", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Algorithm")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Algorithm", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-SignedHeaders", valid_606303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606304: Call_DeleteCluster_606293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ## 
  let valid = call_606304.validator(path, query, header, formData, body)
  let scheme = call_606304.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606304.url(scheme.get, call_606304.host, call_606304.base,
                         call_606304.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606304, url, valid)

proc call*(call_606305: Call_DeleteCluster_606293; name: string): Recallable =
  ## deleteCluster
  ## <p>Deletes the Amazon EKS cluster control plane.</p> <p>If you have active services in your cluster that are associated with a load balancer, you must delete those services before deleting the cluster so that the load balancers are deleted properly. Otherwise, you can have orphaned resources in your VPC that prevent you from being able to delete the VPC. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/delete-cluster.html">Deleting a Cluster</a> in the <i>Amazon EKS User Guide</i>.</p> <p>If you have managed node groups or Fargate profiles attached to the cluster, you must delete them first. For more information, see <a>DeleteNodegroup</a> and<a>DeleteFargateProfile</a>.</p>
  ##   name: string (required)
  ##       : The name of the cluster to delete.
  var path_606306 = newJObject()
  add(path_606306, "name", newJString(name))
  result = call_606305.call(path_606306, nil, nil, nil, nil)

var deleteCluster* = Call_DeleteCluster_606293(name: "deleteCluster",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}", validator: validate_DeleteCluster_606294, base: "/",
    url: url_DeleteCluster_606295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFargateProfile_606307 = ref object of OpenApiRestCall_605590
proc url_DescribeFargateProfile_606309(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeFargateProfile_606308(path: JsonNode; query: JsonNode;
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
  var valid_606310 = path.getOrDefault("name")
  valid_606310 = validateParameter(valid_606310, JString, required = true,
                                 default = nil)
  if valid_606310 != nil:
    section.add "name", valid_606310
  var valid_606311 = path.getOrDefault("fargateProfileName")
  valid_606311 = validateParameter(valid_606311, JString, required = true,
                                 default = nil)
  if valid_606311 != nil:
    section.add "fargateProfileName", valid_606311
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
  var valid_606312 = header.getOrDefault("X-Amz-Signature")
  valid_606312 = validateParameter(valid_606312, JString, required = false,
                                 default = nil)
  if valid_606312 != nil:
    section.add "X-Amz-Signature", valid_606312
  var valid_606313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Content-Sha256", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Date")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Date", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Credential")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Credential", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Security-Token")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Security-Token", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Algorithm")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Algorithm", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-SignedHeaders", valid_606318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606319: Call_DescribeFargateProfile_606307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptive information about an AWS Fargate profile.
  ## 
  let valid = call_606319.validator(path, query, header, formData, body)
  let scheme = call_606319.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606319.url(scheme.get, call_606319.host, call_606319.base,
                         call_606319.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606319, url, valid)

proc call*(call_606320: Call_DescribeFargateProfile_606307; name: string;
          fargateProfileName: string): Recallable =
  ## describeFargateProfile
  ## Returns descriptive information about an AWS Fargate profile.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile.
  ##   fargateProfileName: string (required)
  ##                     : The name of the Fargate profile to describe.
  var path_606321 = newJObject()
  add(path_606321, "name", newJString(name))
  add(path_606321, "fargateProfileName", newJString(fargateProfileName))
  result = call_606320.call(path_606321, nil, nil, nil, nil)

var describeFargateProfile* = Call_DescribeFargateProfile_606307(
    name: "describeFargateProfile", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DescribeFargateProfile_606308, base: "/",
    url: url_DescribeFargateProfile_606309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFargateProfile_606322 = ref object of OpenApiRestCall_605590
proc url_DeleteFargateProfile_606324(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteFargateProfile_606323(path: JsonNode; query: JsonNode;
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
  var valid_606325 = path.getOrDefault("name")
  valid_606325 = validateParameter(valid_606325, JString, required = true,
                                 default = nil)
  if valid_606325 != nil:
    section.add "name", valid_606325
  var valid_606326 = path.getOrDefault("fargateProfileName")
  valid_606326 = validateParameter(valid_606326, JString, required = true,
                                 default = nil)
  if valid_606326 != nil:
    section.add "fargateProfileName", valid_606326
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
  var valid_606327 = header.getOrDefault("X-Amz-Signature")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Signature", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Content-Sha256", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Date")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Date", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Credential")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Credential", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Security-Token")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Security-Token", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Algorithm")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Algorithm", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-SignedHeaders", valid_606333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606334: Call_DeleteFargateProfile_606322; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ## 
  let valid = call_606334.validator(path, query, header, formData, body)
  let scheme = call_606334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606334.url(scheme.get, call_606334.host, call_606334.base,
                         call_606334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606334, url, valid)

proc call*(call_606335: Call_DeleteFargateProfile_606322; name: string;
          fargateProfileName: string): Recallable =
  ## deleteFargateProfile
  ## <p>Deletes an AWS Fargate profile.</p> <p>When you delete a Fargate profile, any pods running on Fargate that were created with the profile are deleted. If those pods match another Fargate profile, then they are scheduled on Fargate with that profile. If they no longer match any Fargate profiles, then they are not scheduled on Fargate and they may remain in a pending state.</p> <p>Only one Fargate profile in a cluster can be in the <code>DELETING</code> status at a time. You must wait for a Fargate profile to finish deleting before you can delete any other profiles in that cluster.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the Fargate profile to delete.
  ##   fargateProfileName: string (required)
  ##                     : The name of the Fargate profile to delete.
  var path_606336 = newJObject()
  add(path_606336, "name", newJString(name))
  add(path_606336, "fargateProfileName", newJString(fargateProfileName))
  result = call_606335.call(path_606336, nil, nil, nil, nil)

var deleteFargateProfile* = Call_DeleteFargateProfile_606322(
    name: "deleteFargateProfile", meth: HttpMethod.HttpDelete,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/fargate-profiles/{fargateProfileName}",
    validator: validate_DeleteFargateProfile_606323, base: "/",
    url: url_DeleteFargateProfile_606324, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeNodegroup_606337 = ref object of OpenApiRestCall_605590
proc url_DescribeNodegroup_606339(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeNodegroup_606338(path: JsonNode; query: JsonNode;
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
  var valid_606340 = path.getOrDefault("name")
  valid_606340 = validateParameter(valid_606340, JString, required = true,
                                 default = nil)
  if valid_606340 != nil:
    section.add "name", valid_606340
  var valid_606341 = path.getOrDefault("nodegroupName")
  valid_606341 = validateParameter(valid_606341, JString, required = true,
                                 default = nil)
  if valid_606341 != nil:
    section.add "nodegroupName", valid_606341
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
  var valid_606342 = header.getOrDefault("X-Amz-Signature")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Signature", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Content-Sha256", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Date")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Date", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Credential")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Credential", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Security-Token")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Security-Token", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Algorithm")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Algorithm", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-SignedHeaders", valid_606348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606349: Call_DescribeNodegroup_606337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns descriptive information about an Amazon EKS node group.
  ## 
  let valid = call_606349.validator(path, query, header, formData, body)
  let scheme = call_606349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606349.url(scheme.get, call_606349.host, call_606349.base,
                         call_606349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606349, url, valid)

proc call*(call_606350: Call_DescribeNodegroup_606337; name: string;
          nodegroupName: string): Recallable =
  ## describeNodegroup
  ## Returns descriptive information about an Amazon EKS node group.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to describe.
  var path_606351 = newJObject()
  add(path_606351, "name", newJString(name))
  add(path_606351, "nodegroupName", newJString(nodegroupName))
  result = call_606350.call(path_606351, nil, nil, nil, nil)

var describeNodegroup* = Call_DescribeNodegroup_606337(name: "describeNodegroup",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DescribeNodegroup_606338, base: "/",
    url: url_DescribeNodegroup_606339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteNodegroup_606352 = ref object of OpenApiRestCall_605590
proc url_DeleteNodegroup_606354(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteNodegroup_606353(path: JsonNode; query: JsonNode;
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
  var valid_606355 = path.getOrDefault("name")
  valid_606355 = validateParameter(valid_606355, JString, required = true,
                                 default = nil)
  if valid_606355 != nil:
    section.add "name", valid_606355
  var valid_606356 = path.getOrDefault("nodegroupName")
  valid_606356 = validateParameter(valid_606356, JString, required = true,
                                 default = nil)
  if valid_606356 != nil:
    section.add "nodegroupName", valid_606356
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
  var valid_606357 = header.getOrDefault("X-Amz-Signature")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Signature", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Content-Sha256", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Date")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Date", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Credential")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Credential", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Security-Token")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Security-Token", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Algorithm")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Algorithm", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-SignedHeaders", valid_606363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606364: Call_DeleteNodegroup_606352; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Amazon EKS node group for a cluster.
  ## 
  let valid = call_606364.validator(path, query, header, formData, body)
  let scheme = call_606364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606364.url(scheme.get, call_606364.host, call_606364.base,
                         call_606364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606364, url, valid)

proc call*(call_606365: Call_DeleteNodegroup_606352; name: string;
          nodegroupName: string): Recallable =
  ## deleteNodegroup
  ## Deletes an Amazon EKS node group for a cluster.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with your node group.
  ##   nodegroupName: string (required)
  ##                : The name of the node group to delete.
  var path_606366 = newJObject()
  add(path_606366, "name", newJString(name))
  add(path_606366, "nodegroupName", newJString(nodegroupName))
  result = call_606365.call(path_606366, nil, nil, nil, nil)

var deleteNodegroup* = Call_DeleteNodegroup_606352(name: "deleteNodegroup",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}",
    validator: validate_DeleteNodegroup_606353, base: "/", url: url_DeleteNodegroup_606354,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeUpdate_606367 = ref object of OpenApiRestCall_605590
proc url_DescribeUpdate_606369(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeUpdate_606368(path: JsonNode; query: JsonNode;
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
  var valid_606370 = path.getOrDefault("updateId")
  valid_606370 = validateParameter(valid_606370, JString, required = true,
                                 default = nil)
  if valid_606370 != nil:
    section.add "updateId", valid_606370
  var valid_606371 = path.getOrDefault("name")
  valid_606371 = validateParameter(valid_606371, JString, required = true,
                                 default = nil)
  if valid_606371 != nil:
    section.add "name", valid_606371
  result.add "path", section
  ## parameters in `query` object:
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS node group associated with the update.
  section = newJObject()
  var valid_606372 = query.getOrDefault("nodegroupName")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "nodegroupName", valid_606372
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
  var valid_606373 = header.getOrDefault("X-Amz-Signature")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Signature", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Content-Sha256", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Date")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Date", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Credential")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Credential", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Security-Token")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Security-Token", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-Algorithm")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-Algorithm", valid_606378
  var valid_606379 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-SignedHeaders", valid_606379
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606380: Call_DescribeUpdate_606367; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ## 
  let valid = call_606380.validator(path, query, header, formData, body)
  let scheme = call_606380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606380.url(scheme.get, call_606380.host, call_606380.base,
                         call_606380.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606380, url, valid)

proc call*(call_606381: Call_DescribeUpdate_606367; updateId: string; name: string;
          nodegroupName: string = ""): Recallable =
  ## describeUpdate
  ## <p>Returns descriptive information about an update against your Amazon EKS cluster or associated managed node group.</p> <p>When the status of the update is <code>Succeeded</code>, the update is complete. If an update fails, the status is <code>Failed</code>, and an error detail explains the reason for the failure.</p>
  ##   updateId: string (required)
  ##           : The ID of the update to describe.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster associated with the update.
  ##   nodegroupName: string
  ##                : The name of the Amazon EKS node group associated with the update.
  var path_606382 = newJObject()
  var query_606383 = newJObject()
  add(path_606382, "updateId", newJString(updateId))
  add(path_606382, "name", newJString(name))
  add(query_606383, "nodegroupName", newJString(nodegroupName))
  result = call_606381.call(path_606382, query_606383, nil, nil, nil)

var describeUpdate* = Call_DescribeUpdate_606367(name: "describeUpdate",
    meth: HttpMethod.HttpGet, host: "eks.amazonaws.com",
    route: "/clusters/{name}/updates/{updateId}",
    validator: validate_DescribeUpdate_606368, base: "/", url: url_DescribeUpdate_606369,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606398 = ref object of OpenApiRestCall_605590
proc url_TagResource_606400(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_606399(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606401 = path.getOrDefault("resourceArn")
  valid_606401 = validateParameter(valid_606401, JString, required = true,
                                 default = nil)
  if valid_606401 != nil:
    section.add "resourceArn", valid_606401
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
  var valid_606402 = header.getOrDefault("X-Amz-Signature")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Signature", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Content-Sha256", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Date")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Date", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-Credential")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-Credential", valid_606405
  var valid_606406 = header.getOrDefault("X-Amz-Security-Token")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Security-Token", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Algorithm")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Algorithm", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-SignedHeaders", valid_606408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606410: Call_TagResource_606398; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ## 
  let valid = call_606410.validator(path, query, header, formData, body)
  let scheme = call_606410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606410.url(scheme.get, call_606410.host, call_606410.base,
                         call_606410.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606410, url, valid)

proc call*(call_606411: Call_TagResource_606398; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified <code>resourceArn</code>. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well. Tags that you create for Amazon EKS resources do not propagate to any other resources associated with the cluster. For example, if you tag a cluster with this operation, that tag does not automatically propagate to the subnets and worker nodes associated with the cluster.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource to which to add tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  ##   body: JObject (required)
  var path_606412 = newJObject()
  var body_606413 = newJObject()
  add(path_606412, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_606413 = body
  result = call_606411.call(path_606412, nil, nil, nil, body_606413)

var tagResource* = Call_TagResource_606398(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "eks.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_606399,
                                        base: "/", url: url_TagResource_606400,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606384 = ref object of OpenApiRestCall_605590
proc url_ListTagsForResource_606386(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606385(path: JsonNode; query: JsonNode;
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
  var valid_606387 = path.getOrDefault("resourceArn")
  valid_606387 = validateParameter(valid_606387, JString, required = true,
                                 default = nil)
  if valid_606387 != nil:
    section.add "resourceArn", valid_606387
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
  var valid_606388 = header.getOrDefault("X-Amz-Signature")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Signature", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Content-Sha256", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Date")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Date", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Credential")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Credential", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Security-Token")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Security-Token", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-Algorithm")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-Algorithm", valid_606393
  var valid_606394 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606394 = validateParameter(valid_606394, JString, required = false,
                                 default = nil)
  if valid_606394 != nil:
    section.add "X-Amz-SignedHeaders", valid_606394
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606395: Call_ListTagsForResource_606384; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the tags for an Amazon EKS resource.
  ## 
  let valid = call_606395.validator(path, query, header, formData, body)
  let scheme = call_606395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606395.url(scheme.get, call_606395.host, call_606395.base,
                         call_606395.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606395, url, valid)

proc call*(call_606396: Call_ListTagsForResource_606384; resourceArn: string): Recallable =
  ## listTagsForResource
  ## List the tags for an Amazon EKS resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) that identifies the resource for which to list the tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  var path_606397 = newJObject()
  add(path_606397, "resourceArn", newJString(resourceArn))
  result = call_606396.call(path_606397, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606384(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "eks.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_606385, base: "/",
    url: url_ListTagsForResource_606386, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterVersion_606432 = ref object of OpenApiRestCall_605590
proc url_UpdateClusterVersion_606434(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterVersion_606433(path: JsonNode; query: JsonNode;
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
  var valid_606435 = path.getOrDefault("name")
  valid_606435 = validateParameter(valid_606435, JString, required = true,
                                 default = nil)
  if valid_606435 != nil:
    section.add "name", valid_606435
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
  var valid_606436 = header.getOrDefault("X-Amz-Signature")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-Signature", valid_606436
  var valid_606437 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606437 = validateParameter(valid_606437, JString, required = false,
                                 default = nil)
  if valid_606437 != nil:
    section.add "X-Amz-Content-Sha256", valid_606437
  var valid_606438 = header.getOrDefault("X-Amz-Date")
  valid_606438 = validateParameter(valid_606438, JString, required = false,
                                 default = nil)
  if valid_606438 != nil:
    section.add "X-Amz-Date", valid_606438
  var valid_606439 = header.getOrDefault("X-Amz-Credential")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Credential", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Security-Token")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Security-Token", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Algorithm")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Algorithm", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-SignedHeaders", valid_606442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606444: Call_UpdateClusterVersion_606432; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ## 
  let valid = call_606444.validator(path, query, header, formData, body)
  let scheme = call_606444.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606444.url(scheme.get, call_606444.host, call_606444.base,
                         call_606444.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606444, url, valid)

proc call*(call_606445: Call_UpdateClusterVersion_606432; name: string;
          body: JsonNode): Recallable =
  ## updateClusterVersion
  ## <p>Updates an Amazon EKS cluster to the specified Kubernetes version. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p> <p>If your cluster has managed node groups attached to it, all of your node groups’ Kubernetes versions must match the cluster’s Kubernetes version in order to update the cluster to a new Kubernetes version.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_606446 = newJObject()
  var body_606447 = newJObject()
  add(path_606446, "name", newJString(name))
  if body != nil:
    body_606447 = body
  result = call_606445.call(path_606446, nil, nil, nil, body_606447)

var updateClusterVersion* = Call_UpdateClusterVersion_606432(
    name: "updateClusterVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/updates",
    validator: validate_UpdateClusterVersion_606433, base: "/",
    url: url_UpdateClusterVersion_606434, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListUpdates_606414 = ref object of OpenApiRestCall_605590
proc url_ListUpdates_606416(protocol: Scheme; host: string; base: string;
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

proc validate_ListUpdates_606415(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606417 = path.getOrDefault("name")
  valid_606417 = validateParameter(valid_606417, JString, required = true,
                                 default = nil)
  if valid_606417 != nil:
    section.add "name", valid_606417
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : The <code>nextToken</code> value returned from a previous paginated <code>ListUpdates</code> request where <code>maxResults</code> was used and the results exceeded the value of that parameter. Pagination continues from the end of the previous results that returned the <code>nextToken</code> value.
  ##   nodegroupName: JString
  ##                : The name of the Amazon EKS managed node group to list updates for.
  ##   maxResults: JInt
  ##             : The maximum number of update results returned by <code>ListUpdates</code> in paginated output. When you use this parameter, <code>ListUpdates</code> returns only <code>maxResults</code> results in a single page along with a <code>nextToken</code> response element. You can see the remaining results of the initial request by sending another <code>ListUpdates</code> request with the returned <code>nextToken</code> value. This value can be between 1 and 100. If you don't use this parameter, <code>ListUpdates</code> returns up to 100 results and a <code>nextToken</code> value if applicable.
  section = newJObject()
  var valid_606418 = query.getOrDefault("nextToken")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "nextToken", valid_606418
  var valid_606419 = query.getOrDefault("nodegroupName")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "nodegroupName", valid_606419
  var valid_606420 = query.getOrDefault("maxResults")
  valid_606420 = validateParameter(valid_606420, JInt, required = false, default = nil)
  if valid_606420 != nil:
    section.add "maxResults", valid_606420
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
  var valid_606421 = header.getOrDefault("X-Amz-Signature")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Signature", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Content-Sha256", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Date")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Date", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Credential")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Credential", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Security-Token")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Security-Token", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Algorithm")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Algorithm", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-SignedHeaders", valid_606427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606428: Call_ListUpdates_606414; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the updates associated with an Amazon EKS cluster or managed node group in your AWS account, in the specified Region.
  ## 
  let valid = call_606428.validator(path, query, header, formData, body)
  let scheme = call_606428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606428.url(scheme.get, call_606428.host, call_606428.base,
                         call_606428.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606428, url, valid)

proc call*(call_606429: Call_ListUpdates_606414; name: string;
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
  var path_606430 = newJObject()
  var query_606431 = newJObject()
  add(query_606431, "nextToken", newJString(nextToken))
  add(path_606430, "name", newJString(name))
  add(query_606431, "nodegroupName", newJString(nodegroupName))
  add(query_606431, "maxResults", newJInt(maxResults))
  result = call_606429.call(path_606430, query_606431, nil, nil, nil)

var listUpdates* = Call_ListUpdates_606414(name: "listUpdates",
                                        meth: HttpMethod.HttpGet,
                                        host: "eks.amazonaws.com",
                                        route: "/clusters/{name}/updates",
                                        validator: validate_ListUpdates_606415,
                                        base: "/", url: url_ListUpdates_606416,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606448 = ref object of OpenApiRestCall_605590
proc url_UntagResource_606450(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_606449(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606451 = path.getOrDefault("resourceArn")
  valid_606451 = validateParameter(valid_606451, JString, required = true,
                                 default = nil)
  if valid_606451 != nil:
    section.add "resourceArn", valid_606451
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606452 = query.getOrDefault("tagKeys")
  valid_606452 = validateParameter(valid_606452, JArray, required = true, default = nil)
  if valid_606452 != nil:
    section.add "tagKeys", valid_606452
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
  var valid_606453 = header.getOrDefault("X-Amz-Signature")
  valid_606453 = validateParameter(valid_606453, JString, required = false,
                                 default = nil)
  if valid_606453 != nil:
    section.add "X-Amz-Signature", valid_606453
  var valid_606454 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Content-Sha256", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Date")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Date", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Credential")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Credential", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Security-Token")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Security-Token", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Algorithm")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Algorithm", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-SignedHeaders", valid_606459
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606460: Call_UntagResource_606448; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes specified tags from a resource.
  ## 
  let valid = call_606460.validator(path, query, header, formData, body)
  let scheme = call_606460.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606460.url(scheme.get, call_606460.host, call_606460.base,
                         call_606460.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606460, url, valid)

proc call*(call_606461: Call_UntagResource_606448; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   resourceArn: string (required)
  ##              : The Amazon Resource Name (ARN) of the resource from which to delete tags. Currently, the supported resources are Amazon EKS clusters and managed node groups.
  ##   tagKeys: JArray (required)
  ##          : The keys of the tags to be removed.
  var path_606462 = newJObject()
  var query_606463 = newJObject()
  add(path_606462, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_606463.add "tagKeys", tagKeys
  result = call_606461.call(path_606462, query_606463, nil, nil, nil)

var untagResource* = Call_UntagResource_606448(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "eks.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_606449,
    base: "/", url: url_UntagResource_606450, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateClusterConfig_606464 = ref object of OpenApiRestCall_605590
proc url_UpdateClusterConfig_606466(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateClusterConfig_606465(path: JsonNode; query: JsonNode;
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
  var valid_606467 = path.getOrDefault("name")
  valid_606467 = validateParameter(valid_606467, JString, required = true,
                                 default = nil)
  if valid_606467 != nil:
    section.add "name", valid_606467
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
  var valid_606468 = header.getOrDefault("X-Amz-Signature")
  valid_606468 = validateParameter(valid_606468, JString, required = false,
                                 default = nil)
  if valid_606468 != nil:
    section.add "X-Amz-Signature", valid_606468
  var valid_606469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Content-Sha256", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Date")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Date", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Credential")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Credential", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Security-Token")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Security-Token", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Algorithm")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Algorithm", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-SignedHeaders", valid_606474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606476: Call_UpdateClusterConfig_606464; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ## 
  let valid = call_606476.validator(path, query, header, formData, body)
  let scheme = call_606476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606476.url(scheme.get, call_606476.host, call_606476.base,
                         call_606476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606476, url, valid)

proc call*(call_606477: Call_UpdateClusterConfig_606464; name: string; body: JsonNode): Recallable =
  ## updateClusterConfig
  ## <p>Updates an Amazon EKS cluster configuration. Your cluster continues to function during the update. The response output includes an update ID that you can use to track the status of your cluster update with the <a>DescribeUpdate</a> API operation.</p> <p>You can use this API operation to enable or disable exporting the Kubernetes control plane logs for your cluster to CloudWatch Logs. By default, cluster control plane logs aren't exported to CloudWatch Logs. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html">Amazon EKS Cluster Control Plane Logs</a> in the <i> <i>Amazon EKS User Guide</i> </i>.</p> <note> <p>CloudWatch Logs ingestion, archive storage, and data scanning rates apply to exported control plane logs. For more information, see <a href="http://aws.amazon.com/cloudwatch/pricing/">Amazon CloudWatch Pricing</a>.</p> </note> <p>You can also use this API operation to enable or disable public and private access to your cluster's Kubernetes API server endpoint. By default, public access is enabled, and private access is disabled. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html">Amazon EKS Cluster Endpoint Access Control</a> in the <i> <i>Amazon EKS User Guide</i> </i>. </p> <important> <p>At this time, you can not update the subnets or security group IDs for an existing cluster.</p> </important> <p>Cluster updates are asynchronous, and they should finish within a few minutes. During an update, the cluster status moves to <code>UPDATING</code> (this status transition is eventually consistent). When the update is complete (either <code>Failed</code> or <code>Successful</code>), the cluster status moves to <code>Active</code>.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster to update.
  ##   body: JObject (required)
  var path_606478 = newJObject()
  var body_606479 = newJObject()
  add(path_606478, "name", newJString(name))
  if body != nil:
    body_606479 = body
  result = call_606477.call(path_606478, nil, nil, nil, body_606479)

var updateClusterConfig* = Call_UpdateClusterConfig_606464(
    name: "updateClusterConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com", route: "/clusters/{name}/update-config",
    validator: validate_UpdateClusterConfig_606465, base: "/",
    url: url_UpdateClusterConfig_606466, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupConfig_606480 = ref object of OpenApiRestCall_605590
proc url_UpdateNodegroupConfig_606482(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNodegroupConfig_606481(path: JsonNode; query: JsonNode;
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
  var valid_606483 = path.getOrDefault("name")
  valid_606483 = validateParameter(valid_606483, JString, required = true,
                                 default = nil)
  if valid_606483 != nil:
    section.add "name", valid_606483
  var valid_606484 = path.getOrDefault("nodegroupName")
  valid_606484 = validateParameter(valid_606484, JString, required = true,
                                 default = nil)
  if valid_606484 != nil:
    section.add "nodegroupName", valid_606484
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
  var valid_606485 = header.getOrDefault("X-Amz-Signature")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Signature", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Content-Sha256", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Date")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Date", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Credential")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Credential", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Security-Token")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Security-Token", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Algorithm")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Algorithm", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-SignedHeaders", valid_606491
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606493: Call_UpdateNodegroupConfig_606480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ## 
  let valid = call_606493.validator(path, query, header, formData, body)
  let scheme = call_606493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606493.url(scheme.get, call_606493.host, call_606493.base,
                         call_606493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606493, url, valid)

proc call*(call_606494: Call_UpdateNodegroupConfig_606480; name: string;
          body: JsonNode; nodegroupName: string): Recallable =
  ## updateNodegroupConfig
  ## Updates an Amazon EKS managed node group configuration. Your node group continues to function during the update. The response output includes an update ID that you can use to track the status of your node group update with the <a>DescribeUpdate</a> API operation. Currently you can update the Kubernetes labels for a node group or the scaling configuration.
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that the managed node group resides in.
  ##   body: JObject (required)
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  var path_606495 = newJObject()
  var body_606496 = newJObject()
  add(path_606495, "name", newJString(name))
  if body != nil:
    body_606496 = body
  add(path_606495, "nodegroupName", newJString(nodegroupName))
  result = call_606494.call(path_606495, nil, nil, nil, body_606496)

var updateNodegroupConfig* = Call_UpdateNodegroupConfig_606480(
    name: "updateNodegroupConfig", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-config",
    validator: validate_UpdateNodegroupConfig_606481, base: "/",
    url: url_UpdateNodegroupConfig_606482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateNodegroupVersion_606497 = ref object of OpenApiRestCall_605590
proc url_UpdateNodegroupVersion_606499(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateNodegroupVersion_606498(path: JsonNode; query: JsonNode;
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
  var valid_606500 = path.getOrDefault("name")
  valid_606500 = validateParameter(valid_606500, JString, required = true,
                                 default = nil)
  if valid_606500 != nil:
    section.add "name", valid_606500
  var valid_606501 = path.getOrDefault("nodegroupName")
  valid_606501 = validateParameter(valid_606501, JString, required = true,
                                 default = nil)
  if valid_606501 != nil:
    section.add "nodegroupName", valid_606501
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
  var valid_606502 = header.getOrDefault("X-Amz-Signature")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Signature", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Content-Sha256", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Date")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Date", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-Credential")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-Credential", valid_606505
  var valid_606506 = header.getOrDefault("X-Amz-Security-Token")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Security-Token", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Algorithm")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Algorithm", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-SignedHeaders", valid_606508
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606510: Call_UpdateNodegroupVersion_606497; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ## 
  let valid = call_606510.validator(path, query, header, formData, body)
  let scheme = call_606510.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606510.url(scheme.get, call_606510.host, call_606510.base,
                         call_606510.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606510, url, valid)

proc call*(call_606511: Call_UpdateNodegroupVersion_606497; name: string;
          body: JsonNode; nodegroupName: string): Recallable =
  ## updateNodegroupVersion
  ## <p>Updates the Kubernetes version or AMI version of an Amazon EKS managed node group.</p> <p>You can update to the latest available AMI version of a node group's current Kubernetes version by not specifying a Kubernetes version in the request. You can update to the latest AMI version of your cluster's current Kubernetes version by specifying your cluster's Kubernetes version in the request. For more information, see <a href="https://docs.aws.amazon.com/eks/latest/userguide/eks-linux-ami-versions.html">Amazon EKS-Optimized Linux AMI Versions</a> in the <i>Amazon EKS User Guide</i>.</p> <p>You cannot roll back a node group to an earlier Kubernetes version or AMI version.</p> <p>When a node in a managed node group is terminated due to a scaling action or update, the pods in that node are drained first. Amazon EKS attempts to drain the nodes gracefully and will fail if it is unable to do so. You can <code>force</code> the update if Amazon EKS is unable to drain the nodes as a result of a pod disruption budget issue.</p>
  ##   name: string (required)
  ##       : The name of the Amazon EKS cluster that is associated with the managed node group to update.
  ##   body: JObject (required)
  ##   nodegroupName: string (required)
  ##                : The name of the managed node group to update.
  var path_606512 = newJObject()
  var body_606513 = newJObject()
  add(path_606512, "name", newJString(name))
  if body != nil:
    body_606513 = body
  add(path_606512, "nodegroupName", newJString(nodegroupName))
  result = call_606511.call(path_606512, nil, nil, nil, body_606513)

var updateNodegroupVersion* = Call_UpdateNodegroupVersion_606497(
    name: "updateNodegroupVersion", meth: HttpMethod.HttpPost,
    host: "eks.amazonaws.com",
    route: "/clusters/{name}/node-groups/{nodegroupName}/update-version",
    validator: validate_UpdateNodegroupVersion_606498, base: "/",
    url: url_UpdateNodegroupVersion_606499, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
